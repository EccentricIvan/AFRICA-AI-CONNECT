import argparse
import json
import random
import re
from pathlib import Path

import pandas as pd


def clean_text(value):
    if value is None:
        return ""

    value = str(value)
    value = value.replace("\ufeff", "")
    value = value.replace("\n", " ")
    value = value.replace("\r", " ")
    value = re.sub(r"\s+", " ", value)

    return value.strip()


def normalize_for_duplicate_check(value):
    value = clean_text(value).lower()
    value = value.replace("“", '"').replace("”", '"')
    value = value.replace("‘", "'").replace("’", "'")
    value = re.sub(r"\s+", " ", value)

    return value.strip()


def is_good_pair(english, target, max_words, max_chars):
    english = clean_text(english)
    target = clean_text(target)

    if not english or not target:
        return False

    if english.lower() in ["nan", "none", "null"]:
        return False

    if target.lower() in ["nan", "none", "null"]:
        return False

    if len(english) < 2 or len(target) < 2:
        return False

    if len(english) > max_chars or len(target) > max_chars:
        return False

    if len(english.split()) > max_words:
        return False

    if len(target.split()) > max_words:
        return False

    if english.strip().lower() == target.strip().lower():
        return False

    return True


def split_dataset(df, seed=42):
    random.seed(seed)

    indexes = list(df.index)
    random.shuffle(indexes)

    total = len(indexes)

    train_end = int(total * 0.90)
    validation_end = train_end + int(total * 0.05)

    train_df = df.loc[indexes[:train_end]].reset_index(drop=True)
    validation_df = df.loc[indexes[train_end:validation_end]].reset_index(drop=True)
    test_df = df.loc[indexes[validation_end:]].reset_index(drop=True)

    return train_df, validation_df, test_df


def save_jsonl(df, output_path, target_column):
    with open(output_path, "w", encoding="utf-8") as file:
        for _, row in df.iterrows():
            record = {
                "english": row["english"],
                target_column: row[target_column],
            }

            file.write(json.dumps(record, ensure_ascii=False) + "\n")


def prepare_dataset(
    input_file,
    output_dir,
    target_column,
    max_words,
    max_chars,
    seed,
):
    input_file = Path(input_file)
    output_dir = Path(output_dir)

    output_dir.mkdir(parents=True, exist_ok=True)

    if not input_file.exists():
        raise FileNotFoundError(f"Input file not found: {input_file}")

    print(f"[Reading] {input_file}")

    df = pd.read_csv(input_file)

    df.columns = [str(column).strip().lower() for column in df.columns]

    if "english" not in df.columns:
        raise ValueError(f"Missing 'english' column. Found columns: {list(df.columns)}")

    if target_column not in df.columns:
        raise ValueError(f"Missing '{target_column}' column. Found columns: {list(df.columns)}")

    original_rows = len(df)

    print(f"[Info] Original rows: {original_rows}")

    cleaned = pd.DataFrame()
    cleaned["english"] = df["english"].apply(clean_text)
    cleaned[target_column] = df[target_column].apply(clean_text)

    print("[Cleaning] Removing empty, broken, identical, and very long rows...")

    cleaned = cleaned[
        cleaned.apply(
            lambda row: is_good_pair(
                row["english"],
                row[target_column],
                max_words=max_words,
                max_chars=max_chars,
            ),
            axis=1,
        )
    ].copy()

    after_basic_cleaning = len(cleaned)

    print(f"[Info] Rows after basic cleaning: {after_basic_cleaning}")

    print("[Dedup] Removing duplicate sentence pairs...")

    cleaned["dedup_key"] = (
        cleaned["english"].apply(normalize_for_duplicate_check)
        + " ||| "
        + cleaned[target_column].apply(normalize_for_duplicate_check)
    )

    before_dedup = len(cleaned)

    cleaned = cleaned.drop_duplicates(subset=["dedup_key"]).copy()

    after_dedup = len(cleaned)

    cleaned = cleaned[["english", target_column]].reset_index(drop=True)

    print(f"[Info] Duplicates removed: {before_dedup - after_dedup}")
    print(f"[Info] Final clean rows: {after_dedup}")

    print("[Split] Creating train, validation, and test sets...")

    train_df, validation_df, test_df = split_dataset(cleaned, seed=seed)

    print(f"[Info] Train rows: {len(train_df)}")
    print(f"[Info] Validation rows: {len(validation_df)}")
    print(f"[Info] Test rows: {len(test_df)}")

    print("[Saving] Writing output files...")

    cleaned.to_csv(output_dir / "all_clean.csv", index=False, encoding="utf-8")
    train_df.to_csv(output_dir / "train.csv", index=False, encoding="utf-8")
    validation_df.to_csv(output_dir / "validation.csv", index=False, encoding="utf-8")
    test_df.to_csv(output_dir / "test.csv", index=False, encoding="utf-8")

    save_jsonl(train_df, output_dir / "train.jsonl", target_column)
    save_jsonl(validation_df, output_dir / "validation.jsonl", target_column)
    save_jsonl(test_df, output_dir / "test.jsonl", target_column)

    with open(output_dir / "summary.txt", "w", encoding="utf-8") as file:
        file.write("Fine-tuning dataset summary\n")
        file.write("===========================\n")
        file.write(f"Input file: {input_file}\n")
        file.write(f"Target column: {target_column}\n")
        file.write(f"Original rows: {original_rows}\n")
        file.write(f"Rows after basic cleaning: {after_basic_cleaning}\n")
        file.write(f"Duplicates removed: {before_dedup - after_dedup}\n")
        file.write(f"Final clean rows: {after_dedup}\n")
        file.write(f"Train rows: {len(train_df)}\n")
        file.write(f"Validation rows: {len(validation_df)}\n")
        file.write(f"Test rows: {len(test_df)}\n")
        file.write(f"Max words per sentence: {max_words}\n")
        file.write(f"Max characters per sentence: {max_chars}\n")

    print("[Done] Dataset prepared successfully.")
    print(f"[Output] {output_dir}")


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input-file", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--target-column", required=True)

    parser.add_argument("--max-words", type=int, default=60)
    parser.add_argument("--max-chars", type=int, default=350)
    parser.add_argument("--seed", type=int, default=42)

    args = parser.parse_args()

    prepare_dataset(
        input_file=args.input_file,
        output_dir=args.output_dir,
        target_column=args.target_column.lower().strip(),
        max_words=args.max_words,
        max_chars=args.max_chars,
        seed=args.seed,
    )


if __name__ == "__main__":
    main()