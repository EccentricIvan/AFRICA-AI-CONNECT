import csv
import os

ENGLISH_FILE = "app/Data/external/opus_opensubtitles_en_sw/OpenSubtitles.en-sw.en"
SWAHILI_FILE = "app/Data/external/opus_opensubtitles_en_sw/OpenSubtitles.en-sw.sw"

RAW_OUTPUT = "app/Data/external/opus_swahili_english_raw.csv"
CORRECTION_OUTPUT = "app/Data/processed/opus_swahili_correction_candidates.csv"


def clean_text(text: str) -> str:
    return text.strip().replace("\n", " ").replace("\r", " ")


def is_good_pair(english: str, swahili: str) -> bool:
    if not english or not swahili:
        return False

    if len(english) < 3 or len(swahili) < 3:
        return False

    if len(english) > 300 or len(swahili) > 300:
        return False

    return True


def main():
    if not os.path.exists(ENGLISH_FILE):
        raise FileNotFoundError(f"Missing English file: {ENGLISH_FILE}")

    if not os.path.exists(SWAHILI_FILE):
        raise FileNotFoundError(f"Missing Swahili file: {SWAHILI_FILE}")

    os.makedirs("app/Data/external", exist_ok=True)
    os.makedirs("app/Data/processed", exist_ok=True)

    print("Reading OPUS OpenSubtitles English-Swahili files...")

    with open(ENGLISH_FILE, "r", encoding="utf-8", errors="ignore") as en_file:
        english_lines = en_file.readlines()

    with open(SWAHILI_FILE, "r", encoding="utf-8", errors="ignore") as sw_file:
        swahili_lines = sw_file.readlines()

    print(f"English lines: {len(english_lines)}")
    print(f"Swahili lines: {len(swahili_lines)}")

    total_pairs = min(len(english_lines), len(swahili_lines))
    saved_count = 0
    seen_pairs = set()

    with open(RAW_OUTPUT, "w", newline="", encoding="utf-8") as raw_file, \
         open(CORRECTION_OUTPUT, "w", newline="", encoding="utf-8") as correction_file:

        raw_writer = csv.writer(raw_file)
        raw_writer.writerow(["id", "english", "swahili", "source", "approved"])

        correction_writer = csv.writer(correction_file)
        correction_writer.writerow([
            "id",
            "language",
            "english_message",
            "machine_or_dataset_swahili",
            "correct_natural_swahili",
            "issue_type",
            "domain",
            "reviewer",
            "approved"
        ])

        for index in range(total_pairs):
            english = clean_text(english_lines[index])
            swahili = clean_text(swahili_lines[index])

            if not is_good_pair(english, swahili):
                continue

            pair_key = (english.lower(), swahili.lower())

            if pair_key in seen_pairs:
                continue

            seen_pairs.add(pair_key)
            saved_count += 1

            raw_writer.writerow([
                saved_count,
                english,
                swahili,
                "OPUS OpenSubtitles en-sw",
                "no"
            ])

            correction_writer.writerow([
                saved_count,
                "swahili",
                english,
                swahili,
                "",
                "needs native review",
                "conversation",
                "pending",
                "no"
            ])

    print("Done.")
    print(f"Saved clean pairs: {saved_count}")
    print(f"Raw output: {RAW_OUTPUT}")
    print(f"Correction candidates: {CORRECTION_OUTPUT}")


if __name__ == "__main__":
    main()