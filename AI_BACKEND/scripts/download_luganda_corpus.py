import csv
import os
from datasets import load_dataset


DATASET_NAME = "kambale/luganda-english-parallel-corpus"

RAW_OUTPUT = "app/Data/external/luganda_english_parallel_raw.csv"
CORRECTION_OUTPUT = "app/Data/processed/luganda_correction_candidates.csv"


def clean_text(value: str) -> str:
    if value is None:
        return ""

    return str(value).strip().replace("\n", " ").replace("\r", " ")


def main():
    print("Loading Luganda-English dataset from Hugging Face...")
    print(f"Dataset: {DATASET_NAME}")

    hf_token = os.getenv("HUGGINGFACE_TOKEN")

    if hf_token:
        dataset = load_dataset(DATASET_NAME, split="train", token=hf_token)
    else:
        dataset = load_dataset(DATASET_NAME, split="train")

    print(f"Loaded rows: {len(dataset)}")

    os.makedirs("app/Data/external", exist_ok=True)
    os.makedirs("app/Data/processed", exist_ok=True)

    with open(RAW_OUTPUT, "w", newline="", encoding="utf-8") as raw_file:
        writer = csv.writer(raw_file)
        writer.writerow(["id", "english", "luganda", "source", "approved"])

        for index, row in enumerate(dataset, start=1):
            english = clean_text(row.get("english", ""))
            luganda = clean_text(row.get("luganda", ""))

            if not english or not luganda:
                continue

            writer.writerow([
                index,
                english,
                luganda,
                DATASET_NAME,
                "no"
            ])

    with open(CORRECTION_OUTPUT, "w", newline="", encoding="utf-8") as correction_file:
        writer = csv.writer(correction_file)
        writer.writerow([
            "id",
            "language",
            "english_message",
            "machine_or_dataset_luganda",
            "correct_natural_luganda",
            "issue_type",
            "domain",
            "reviewer",
            "approved"
        ])

        for index, row in enumerate(dataset, start=1):
            english = clean_text(row.get("english", ""))
            luganda = clean_text(row.get("luganda", ""))

            if not english or not luganda:
                continue

            writer.writerow([
                index,
                "luganda",
                english,
                luganda,
                "",
                "needs native review",
                "general",
                "pending",
                "no"
            ])

    print("Done.")
    print(f"Raw dataset saved to: {RAW_OUTPUT}")
    print(f"Correction candidates saved to: {CORRECTION_OUTPUT}")


if __name__ == "__main__":
    main()