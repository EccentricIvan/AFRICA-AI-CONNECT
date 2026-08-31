import csv
import os
import random


INPUT_FILE = "app/Data/processed/luganda_correction_candidates.csv"
OUTPUT_FILE = "app/Data/processed/luganda_review_sample_100.csv"


def main():
    if not os.path.exists(INPUT_FILE):
        raise FileNotFoundError(f"Missing file: {INPUT_FILE}")

    with open(INPUT_FILE, "r", encoding="utf-8") as file:
        reader = list(csv.DictReader(file))

    sample_size = min(100, len(reader))
    sampled_rows = random.sample(reader, sample_size)

    os.makedirs("app/Data/processed", exist_ok=True)

    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as file:
        fieldnames = [
            "id",
            "language",
            "english_message",
            "machine_or_dataset_luganda",
            "correct_natural_luganda",
            "issue_type",
            "domain",
            "reviewer",
            "approved",
        ]

        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()

        for index, row in enumerate(sampled_rows, start=1):
            writer.writerow({
                "id": index,
                "language": row.get("language", "luganda"),
                "english_message": row.get("english_message", ""),
                "machine_or_dataset_luganda": row.get("machine_or_dataset_luganda", ""),
                "correct_natural_luganda": "",
                "issue_type": "needs native review",
                "domain": "general",
                "reviewer": "pending",
                "approved": "no",
            })

    print(f"Created review sample: {OUTPUT_FILE}")
    print(f"Rows: {sample_size}")


if __name__ == "__main__":
    main()