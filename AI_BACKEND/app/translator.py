"""Local NLLB translation engine with Luganda and Swahili LoRA adapters."""
from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from pathlib import Path
from threading import RLock

from app.translation_quality import (
    record_low_confidence,
    score_candidate,
    translation_memory,
)
from app.services.sunbird_service import SunbirdError, sunbird_service

logger = logging.getLogger(__name__)
PROJECT_ROOT = Path(__file__).resolve().parent.parent
BASE_MODEL_PATH = PROJECT_ROOT / "nllb_600m_base"
LUGANDA_ADAPTER_PATH = PROJECT_ROOT / "otic_nllb_luganda_lora_full_final"
SWAHILI_ADAPTER_PATH = PROJECT_ROOT / "otic_nllb_swahili_lora_full_final"
TARGET_LANGUAGES = {"lug": "lug_Latn", "swa": "swh_Latn"}
ADAPTER_NAMES = {"lug": "luganda", "swa": "swahili"}


@dataclass(frozen=True)
class TranslationResult:
    text: str
    confidence: float | None
    meaning_similarity: float | None
    source: str
    alternatives_evaluated: int


class LocalTranslator:
    """Thread-safe, lazily loaded translator backed entirely by local files."""

    def __init__(self) -> None:
        self.device = "not_initialized"
        self.tokenizer = None
        self.model = None
        self._torch = None
        self._load_lock = RLock()
        self._inference_lock = RLock()
        self.load_error: str | None = None

    @property
    def is_initialized(self) -> bool:
        return self.tokenizer is not None and self.model is not None

    def initialize(self) -> None:
        if self.is_initialized:
            return
        with self._load_lock:
            if self.is_initialized:
                return
            required = (BASE_MODEL_PATH, LUGANDA_ADAPTER_PATH, SWAHILI_ADAPTER_PATH)
            missing = [str(path) for path in required if not path.is_dir()]
            if missing:
                raise FileNotFoundError(f"Missing model directories: {', '.join(missing)}")
            try:
                import torch
                from peft import PeftModel
                from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

                device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
                logger.info("Loading local NLLB model from %s", BASE_MODEL_PATH)
                tokenizer = AutoTokenizer.from_pretrained(str(BASE_MODEL_PATH), local_files_only=True)
                dtype = torch.float16 if device.type == "cuda" else torch.float32
                base_model = AutoModelForSeq2SeqLM.from_pretrained(
                    str(BASE_MODEL_PATH), dtype=dtype, local_files_only=True
                )
                model = PeftModel.from_pretrained(
                    base_model, str(LUGANDA_ADAPTER_PATH), adapter_name="luganda", is_trainable=False
                )
                model.load_adapter(
                    str(SWAHILI_ADAPTER_PATH), adapter_name="swahili", is_trainable=False
                )
                model.to(device)
                model.eval()
                self.tokenizer, self.model = tokenizer, model
                self._torch = torch
                self.device = device
                self.load_error = None
                logger.info("Translation model loaded on %s", self.device)
            except Exception as exc:
                self.load_error = str(exc)
                logger.exception("Could not initialize the translation model")
                raise RuntimeError(f"Could not initialize translation model: {exc}") from exc

    def translate_detailed(self, text: str, target_lang: str) -> TranslationResult:
        clean_text = text.strip()
        if not clean_text:
            raise ValueError("text must not be empty")
        language = target_lang.strip().lower()
        if language not in TARGET_LANGUAGES:
            raise ValueError("target_lang must be either 'lug' or 'swa'")

        remembered = translation_memory.lookup(clean_text, language)
        if remembered:
            return TranslationResult(remembered, 1.0, 1.0, "approved_correction", 0)

        provider = os.getenv("TRANSLATION_PROVIDER", "auto").strip().lower()
        if provider not in {"auto", "sunbird", "local"}:
            raise ValueError("TRANSLATION_PROVIDER must be 'auto', 'sunbird', or 'local'")
        if provider != "local" and sunbird_service.is_configured:
            try:
                translated = sunbird_service.translate(clean_text, language)
                return TranslationResult(translated, None, None, "sunbird", 1)
            except SunbirdError as exc:
                logger.warning("Sunbird unavailable; using local LoRA fallback: %s", exc)

        self.initialize()
        assert self.tokenizer is not None and self.model is not None and self._torch is not None
        target_code = TARGET_LANGUAGES[language]
        forced_bos_token_id = self.tokenizer.convert_tokens_to_ids(target_code)
        if forced_bos_token_id == self.tokenizer.unk_token_id:
            raise RuntimeError(f"Tokenizer does not support language code {target_code}")
        with self._inference_lock:
            self.model.set_adapter(ADAPTER_NAMES[language])
            self.tokenizer.src_lang = "eng_Latn"
            inputs = self.tokenizer(
                clean_text, return_tensors="pt", truncation=True, max_length=512
            ).to(self.device)
            with self._torch.no_grad():
                output = self.model.generate(
                    **inputs, forced_bos_token_id=forced_bos_token_id,
                    max_length=256,
                    num_beams=5,
                    num_return_sequences=4,
                    no_repeat_ngram_size=3,
                    repetition_penalty=1.1,
                    early_stopping=True,
                    return_dict_in_generate=True,
                    output_scores=True,
                )
        candidates = self.tokenizer.batch_decode(output.sequences, skip_special_tokens=True)
        sequence_scores = output.sequences_scores.tolist()
        back_translations = self._back_translate(candidates, TARGET_LANGUAGES[language])
        scored = [
            score_candidate(clean_text, candidate, model_score, back_translation)
            for candidate, model_score, back_translation in zip(
                candidates, sequence_scores, back_translations
            )
        ]
        best = max(scored, key=lambda item: item.score)
        record_low_confidence(clean_text, best.text, language, best.confidence)
        return TranslationResult(
            best.text, best.confidence, best.meaning_similarity, "model", len(scored)
        )

    def _back_translate(self, candidates: list[str], source_code: str) -> list[str]:
        """Translate candidates back to English with adapters disabled."""
        assert self.tokenizer is not None and self.model is not None and self._torch is not None
        self.tokenizer.src_lang = source_code
        inputs = self.tokenizer(
            candidates, return_tensors="pt", padding=True, truncation=True, max_length=512
        ).to(self.device)
        english_bos_id = self.tokenizer.convert_tokens_to_ids("eng_Latn")
        with self.model.disable_adapter(), self._torch.no_grad():
            outputs = self.model.generate(
                **inputs, forced_bos_token_id=english_bos_id, max_length=256, num_beams=2
            )
        return self.tokenizer.batch_decode(outputs, skip_special_tokens=True)

    def translate(self, text: str, target_lang: str) -> str:
        return self.translate_detailed(text, target_lang).text


translator = LocalTranslator()
