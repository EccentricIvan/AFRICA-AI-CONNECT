"""Local translation memory and deterministic candidate quality scoring."""
from __future__ import annotations

import csv
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
from threading import Lock

DATA_DIR = Path(__file__).resolve().parent / "Data"
CORRECTIONS_FILE = DATA_DIR / "corrections.csv"
LOW_CONFIDENCE_FILE = DATA_DIR / "low_confidence.csv"
_audit_lock = Lock()

LANGUAGE_ALIASES = {
    "lug": "lug", "lg": "lug", "luganda": "lug",
    "swa": "swa", "sw": "swa", "swh": "swa", "swahili": "swa", "kiswahili": "swa",
}
COMMON_ENGLISH = {
    "and", "are", "can", "for", "from", "have", "help", "how", "is", "of",
    "please", "the", "this", "to", "was", "welcome", "what", "when", "where", "with", "you", "your",
}
TOKEN_RE = re.compile(r"[\w'-]+", re.UNICODE)
PROTECTED_RE = re.compile(
    r"https?://\S+|\b[\w.+-]+@[\w.-]+\.\w+\b|\b[A-Z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)+\b|\b[A-Z]{2,}\b"
)


def normalize(text: str) -> str:
    return " ".join(TOKEN_RE.findall(text.casefold()))


def protected_terms(text: str) -> tuple[str, ...]:
    return tuple(dict.fromkeys(PROTECTED_RE.findall(text)))


class TranslationMemory:
    """Reload approved exact corrections whenever the CSV changes."""

    def __init__(self, path: Path = CORRECTIONS_FILE) -> None:
        self.path = path
        self._modified_ns: int | None = None
        self._entries: dict[tuple[str, str], str] = {}

    def lookup(self, source: str, language: str) -> str | None:
        self._reload_if_changed()
        return self._entries.get((language, normalize(source)))

    def _reload_if_changed(self) -> None:
        try:
            modified_ns = self.path.stat().st_mtime_ns
        except FileNotFoundError:
            self._entries = {}
            self._modified_ns = None
            return
        if modified_ns == self._modified_ns:
            return

        entries: dict[tuple[str, str], str] = {}
        with self.path.open("r", newline="", encoding="utf-8") as stream:
            for row in csv.DictReader(stream):
                if row.get("approved", "").strip().casefold() not in {"yes", "true", "1"}:
                    continue
                language = LANGUAGE_ALIASES.get(row.get("language", "").strip().casefold())
                source = normalize(row.get("user_message", ""))
                correction = row.get("correct_response", "").strip()
                if language and source and correction:
                    entries[(language, source)] = correction
        self._entries = entries
        self._modified_ns = modified_ns


@dataclass(frozen=True)
class ScoredCandidate:
    text: str
    score: float
    confidence: float
    meaning_similarity: float


def meaning_similarity(source: str, back_translation: str) -> float:
    source_normalized = normalize(source)
    back_normalized = normalize(back_translation)
    if not source_normalized or not back_normalized:
        return 0.0
    return SequenceMatcher(None, source_normalized, back_normalized).ratio()


def score_candidate(
    source: str,
    candidate: str,
    model_score: float,
    back_translation: str = "",
) -> ScoredCandidate:
    """Combine model likelihood with conservative, language-agnostic checks."""
    words = TOKEN_RE.findall(candidate.casefold())
    if not words:
        return ScoredCandidate(candidate, -1000.0, 0.0, 0.0)

    score = float(model_score)
    unique_ratio = len(set(words)) / len(words)
    if unique_ratio < 0.55:
        score -= (0.55 - unique_ratio) * 8.0

    english_hits = sum(word in COMMON_ENGLISH for word in words)
    score -= min(english_hits / len(words), 0.5) * 3.0

    missing_terms = sum(term.casefold() not in candidate.casefold() for term in protected_terms(source))
    score -= missing_terms * 1.5

    source_words = TOKEN_RE.findall(source)
    length_ratio = len(words) / max(len(source_words), 1)
    if length_ratio < 0.35:
        score -= (0.35 - length_ratio) * 3.0
    elif length_ratio > 2.8:
        score -= min(length_ratio - 2.8, 3.0)

    similarity = meaning_similarity(source, back_translation)
    score += similarity * 2.0
    # Model-only confidence measures candidate selection, not native-speaker
    # certification. Reserve 1.0 for explicitly approved corrections.
    confidence = max(0.0, min(0.85, 0.55 + similarity * 0.3 + score / 20.0))
    return ScoredCandidate(candidate.strip(), score, confidence, similarity)


translation_memory = TranslationMemory()


def record_low_confidence(
    source: str, translation: str, language: str, confidence: float
) -> None:
    """Append uncertain model output for optional review without blocking inference."""
    if confidence >= 0.55:
        return
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with _audit_lock:
        needs_header = not LOW_CONFIDENCE_FILE.exists() or LOW_CONFIDENCE_FILE.stat().st_size == 0
        with LOW_CONFIDENCE_FILE.open("a", newline="", encoding="utf-8") as stream:
            writer = csv.writer(stream)
            if needs_header:
                writer.writerow(("timestamp", "language", "source", "translation", "confidence"))
            writer.writerow((
                datetime.now(timezone.utc).isoformat(), language, source,
                translation, f"{confidence:.4f}",
            ))
