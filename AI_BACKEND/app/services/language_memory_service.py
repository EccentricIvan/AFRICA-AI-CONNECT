import csv
import os
from difflib import SequenceMatcher


BASE_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "Data")
)

MAX_ROWS_PER_LANGUAGE = 10000


DATASET_PATHS = {
    "luganda": {
        "path": os.path.join(BASE_DIR, "external", "luganda_english_parallel_raw.csv"),
        "target_column": "luganda",
    },
    "swahili": {
        "path": os.path.join(BASE_DIR, "external", "opus_swahili_english_raw.csv"),
        "target_column": "swahili",
    },
}


def normalize_text(text: str) -> str:
    return " ".join(str(text).lower().strip().split())


def similarity(a: str, b: str) -> float:
    return SequenceMatcher(None, normalize_text(a), normalize_text(b)).ratio()


class LanguageMemoryService:
    def __init__(self):
        self.parallel_examples = {
            "luganda": [],
            "swahili": [],
        }

        self.load_all_datasets()

    def load_all_datasets(self):
        for language, config in DATASET_PATHS.items():
            self.load_parallel_dataset(
                language=language,
                path=config["path"],
                target_column=config["target_column"],
            )

    def load_parallel_dataset(self, language: str, path: str, target_column: str):
        if not os.path.exists(path):
            print(f"[LanguageMemory] Missing dataset for {language}: {path}")
            return

        loaded_count = 0

        with open(path, "r", encoding="utf-8", errors="ignore") as file:
            reader = csv.DictReader(file)

            for row in reader:
                english = str(row.get("english", "")).strip()
                target = str(row.get(target_column, "")).strip()

                if not english or not target:
                    continue

                if len(english) > 300 or len(target) > 300:
                    continue

                self.parallel_examples[language].append({
                    "english": english,
                    "target": target,
                })

                loaded_count += 1

                if loaded_count >= MAX_ROWS_PER_LANGUAGE:
                    break

        print(f"[LanguageMemory] Loaded {loaded_count} {language} examples.")

    def get_examples(self, language: str, english_text: str, limit: int = 1):

        if not english_text.strip():
            return []

        scored_examples = []

        for example in self.parallel_examples[language]:
            score = similarity(english_text, example["english"])

            if score >= 0.18:
                scored_examples.append((score, example))

        scored_examples.sort(key=lambda item: item[0], reverse=True)

        return [
            example
            for _, example in scored_examples[:limit]
        ]

    def find_close_translation(self, language: str, english_text: str, threshold: float = 0.92):
        if language not in self.parallel_examples:
            return None

        best_score = 0
        best_example = None

        for example in self.parallel_examples[language]:
            score = similarity(english_text, example["english"])

            if score > best_score:
                best_score = score
                best_example = example

        if best_example and best_score >= threshold:
            return best_example["target"]

        return None


language_memory_service = LanguageMemoryService()