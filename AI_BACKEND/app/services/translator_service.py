from pathlib import Path

import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
from peft import PeftModel


MODEL_NAME = "facebook/nllb-200-distilled-600M"

BASE_DIR = Path(__file__).resolve().parents[2]

LORA_ROOT = BASE_DIR / "ai_models" / "nllb_lora"
LUGANDA_ADAPTER_DIR = LORA_ROOT / "luganda"
SWAHILI_ADAPTER_DIR = LORA_ROOT / "swahili"


LANGUAGE_ALIASES = {
    "en": "english",
    "eng": "english",
    "english": "english",

    "lg": "luganda",
    "lug": "luganda",
    "luganda": "luganda",

    "sw": "swahili",
    "swa": "swahili",
    "swh": "swahili",
    "kiswahili": "swahili",
    "swahili": "swahili",
}


NLLB_LANGUAGE_CODES = {
    "english": "eng_Latn",
    "luganda": "lug_Latn",
    "swahili": "swh_Latn",
}


class TranslatorService:
    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.dtype = torch.float16 if self.device == "cuda" else torch.float32
        self.loaded_adapters = set()

        print(f"[Translator] Loading tokenizer: {MODEL_NAME}")
        self.tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

        print(f"[Translator] Loading base NLLB model on {self.device}")
        self.model = AutoModelForSeq2SeqLM.from_pretrained(
            MODEL_NAME,
            torch_dtype=self.dtype,
        )

        self.load_lora_adapters_if_available()

        self.model.to(self.device)
        self.model.eval()

        print("[Translator] Translator service ready.")

    def normalize_language(self, language: str) -> str:
        cleaned = str(language).lower().strip()

        if cleaned not in LANGUAGE_ALIASES:
            raise ValueError(f"Unsupported language: {language}")

        return LANGUAGE_ALIASES[cleaned]

    def load_lora_adapters_if_available(self):
        luganda_config = LUGANDA_ADAPTER_DIR / "adapter_config.json"
        swahili_config = SWAHILI_ADAPTER_DIR / "adapter_config.json"

        if luganda_config.exists():
            print(f"[Translator] Loading Luganda LoRA adapter from {LUGANDA_ADAPTER_DIR}")

            self.model = PeftModel.from_pretrained(
                self.model,
                str(LUGANDA_ADAPTER_DIR),
                adapter_name="luganda",
            )

            self.loaded_adapters.add("luganda")
        else:
            print("[Translator] Luganda LoRA adapter not found. Using base NLLB for Luganda.")

        if swahili_config.exists():
            print(f"[Translator] Loading Swahili LoRA adapter from {SWAHILI_ADAPTER_DIR}")

            if isinstance(self.model, PeftModel):
                self.model.load_adapter(
                    str(SWAHILI_ADAPTER_DIR),
                    adapter_name="swahili",
                )
            else:
                self.model = PeftModel.from_pretrained(
                    self.model,
                    str(SWAHILI_ADAPTER_DIR),
                    adapter_name="swahili",
                )

            self.loaded_adapters.add("swahili")
        else:
            print("[Translator] Swahili LoRA adapter not found. Using base NLLB for Swahili.")

        if self.loaded_adapters:
            print(f"[Translator] Loaded LoRA adapters: {sorted(self.loaded_adapters)}")
        else:
            print("[Translator] No LoRA adapters loaded.")

    def get_adapter_for_direction(self, source_language: str, target_language: str):
        if source_language == "english" and target_language == "luganda":
            if "luganda" in self.loaded_adapters:
                return "luganda"

        if source_language == "english" and target_language == "swahili":
            if "swahili" in self.loaded_adapters:
                return "swahili"

        return None

    def generate_translation(
        self,
        text: str,
        source_code: str,
        target_code: str,
        adapter_name=None,
    ) -> str:
        self.tokenizer.src_lang = source_code

        inputs = self.tokenizer(
            text,
            return_tensors="pt",
            truncation=True,
            max_length=256,
        ).to(self.device)

        forced_bos_token_id = self.tokenizer.convert_tokens_to_ids(target_code)

        with torch.no_grad():
            if adapter_name and isinstance(self.model, PeftModel):
                self.model.set_adapter(adapter_name)

                output_tokens = self.model.generate(
                    **inputs,
                    forced_bos_token_id=forced_bos_token_id,
                    max_length=256,
                    num_beams=4,
                )

            else:
                if isinstance(self.model, PeftModel):
                    with self.model.disable_adapter():
                        output_tokens = self.model.generate(
                            **inputs,
                            forced_bos_token_id=forced_bos_token_id,
                            max_length=256,
                            num_beams=4,
                        )
                else:
                    output_tokens = self.model.generate(
                        **inputs,
                        forced_bos_token_id=forced_bos_token_id,
                        max_length=256,
                        num_beams=4,
                    )

        return self.tokenizer.batch_decode(
            output_tokens,
            skip_special_tokens=True,
        )[0].strip()

    def translate(self, source_language: str, target_language: str, text: str) -> str:
        text = str(text).strip()

        if not text:
            return ""

        source_language = self.normalize_language(source_language)
        target_language = self.normalize_language(target_language)

        if source_language == target_language:
            return text

        source_code = NLLB_LANGUAGE_CODES[source_language]
        target_code = NLLB_LANGUAGE_CODES[target_language]

        adapter_name = self.get_adapter_for_direction(
            source_language=source_language,
            target_language=target_language,
        )

        if adapter_name:
            print(f"[Translator] Using fine-tuned {adapter_name} adapter.")
        else:
            print("[Translator] Using base NLLB translation.")

        try:
            return self.generate_translation(
                text=text,
                source_code=source_code,
                target_code=target_code,
                adapter_name=adapter_name,
            )

        except Exception as error:
            print(f"[Translator Error] {error}")
            return ""


translator_service = TranslatorService()