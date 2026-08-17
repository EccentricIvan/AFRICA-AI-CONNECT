"""Generate complete offline Flutter UI translation bundles via the public API."""
from __future__ import annotations

import json
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[1]
SOURCE_FILE = ROOT / "lib" / "core" / "l10n" / "app_strings.dart"
OUTPUT_DIR = ROOT / "assets" / "localization"
API_URL = "https://otic-connect-api.vercel.app/translate"
SUNBIRD_CHAT_URL = "https://api.sunbird.ai/tasks/chat/completions"
SUNBIRD_TRANSLATE_URL = "https://api.sunbird.ai/tasks/translate"
LANGUAGES = ("lug", "swa", "nyn", "teo", "nyo", "ach")
LANGUAGE_NAMES = {
    "lug": "Luganda", "swa": "Swahili", "nyn": "Runyankore",
    "teo": "Ateso", "nyo": "Runyoro", "ach": "Acholi",
}


def sunbird_token() -> str:
    env_file = ROOT / "AI_BACKEND" / ".env"
    for line in env_file.read_text(encoding="utf-8").splitlines():
        if line.startswith("SUNBIRD_API_TOKEN="):
            token = line.split("=", 1)[1].strip().strip('"').strip("'")
            if token:
                return token
    raise RuntimeError("SUNBIRD_API_TOKEN is not configured")


def _dart_strings(text: str) -> list[str]:
    tokens = re.findall(r"'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"", text)
    values: list[str] = []
    for token in tokens:
        value = token[1:-1]
        value = value.replace(r"\'", "'").replace(r'\"', '"')
        value = value.replace(r"\n", "\n").replace(r"\\", "\\")
        values.append(value)
    return values


def source_strings() -> dict[str, str]:
    source = SOURCE_FILE.read_text(encoding="utf-8")
    mapping: dict[str, str] = {}
    blocks = list(re.finditer(r"^    '([^']+)': \{", source, re.MULTILINE))
    for index, match in enumerate(blocks):
        end = blocks[index + 1].start() if index + 1 < len(blocks) else source.index("  };", match.end())
        block = source[match.end():end]
        english = re.search(
            r"AppLocale\.en:\s*(.*?)(?=,\s*AppLocale\.|,\s*})",
            block,
            re.DOTALL,
        )
        if not english:
            raise RuntimeError(f"Missing English text for {match.group(1)}")
        parts = _dart_strings(english.group(1))
        if not parts:
            raise RuntimeError(f"Could not parse English text for {match.group(1)}")
        mapping[match.group(1)] = "".join(parts)

    literals_match = re.search(
        r"static const _uiLiterals = <String>\[(.*?)\n  \];", source, re.DOTALL
    )
    if not literals_match:
        raise RuntimeError("Could not find UI literals")
    for index, value in enumerate(_dart_strings(literals_match.group(1))):
        mapping[f"__literal_{index}"] = value
    return mapping


def chunks(entries: list[tuple[str, str]], limit: int = 2200) -> list[list[tuple[str, str]]]:
    result: list[list[tuple[str, str]]] = []
    current: list[tuple[str, str]] = []
    size = 0
    for entry in entries:
        entry_size = len(entry[0]) + len(entry[1]) + 5
        if current and size + entry_size > limit:
            result.append(current)
            current, size = [], 0
        current.append(entry)
        size += entry_size
    if current:
        result.append(current)
    return result


def request_translation(language: str, entries: list[tuple[str, str]]) -> dict[str, str]:
    text = "\n".join(f"{key}|||{value.replace(chr(10), ' ')}" for key, value in entries)
    for attempt in range(4):
        try:
            response = requests.post(
                API_URL,
                json={"text": text, "target_lang": language},
                timeout=110,
            )
            response.raise_for_status()
            output = response.json()["translated_text"]
            translated: dict[str, str] = {}
            expected = {key for key, _ in entries}
            for line in output.splitlines():
                if "|||" not in line:
                    continue
                key, value = line.split("|||", 1)
                key = key.strip()
                if key in expected and value.strip():
                    translated[key] = value.strip()
            return translated
        except (requests.RequestException, KeyError, TypeError, ValueError):
            if attempt == 3:
                raise
            time.sleep(2 ** attempt)
    return {}


def request_sunflower_translation(
    language: str, entries: list[tuple[str, str]]
) -> dict[str, str]:
    text = "\n".join(f"{key}|||{value.replace(chr(10), ' ')}" for key, value in entries)
    prompt = (
        f"Translate EVERY value after ||| into natural {LANGUAGE_NAMES[language]}. "
        "Do not leave ordinary English words, labels, or sentences untranslated. "
        "Keep keys before ||| exactly unchanged. Keep brand names, personal names, place "
        "names, numbers, UGX, and acronyms unchanged. Return exactly one key|||translation "
        f"per line, with no commentary or markdown.\n\n{text}"
    )
    response = requests.post(
        SUNBIRD_CHAT_URL,
        headers={
            "Authorization": f"Bearer {sunbird_token()}",
            "Content-Type": "application/json",
        },
        json={
            "model": "sunflower-9b",
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.1,
            "max_tokens": 3000,
        },
        timeout=180,
    )
    response.raise_for_status()
    output = response.json()["choices"][0]["message"]["content"]
    expected = {key for key, _ in entries}
    translated: dict[str, str] = {}
    for line in output.replace("```", "").splitlines():
        if "|||" not in line:
            continue
        key, value = line.split("|||", 1)
        key = key.strip()
        if key in expected and value.strip():
            translated[key] = value.strip()
    return translated


def repair_unchanged(
    language: str, source: dict[str, str], translated: dict[str, str]
) -> dict[str, str]:
    protected_values = {
        "AI Connect Africa", "Kampala Women Entrepreneurs", "Digital Skills Network",
        "Farmers United", "Young Mothers Support", "NGO Partner · Kampala",
        "Tech Hub · Remote", "District Gov · Mbale", "Women's Centre · Jinja",
        "Uganda Police Emergency", "Uganda Emergency Services (alt.)",
    }
    for key, value in source.items():
        if value in protected_values:
            translated[key] = value
    unchanged = [
        (key, source[key])
        for key in source
        if source[key] not in protected_values
        and translated[key].casefold() == source[key].casefold()
        and re.search(r"[A-Za-z]{3}", source[key])
    ]
    if not unchanged:
        return translated

    def translate_one(entry: tuple[str, str]) -> tuple[str, str]:
        key, value = entry
        for attempt in range(8):
            try:
                response = requests.post(
                    SUNBIRD_TRANSLATE_URL,
                    headers={
                        "Authorization": f"Bearer {sunbird_token()}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "text": value.replace("\n", " "),
                        "source_language": "eng",
                        "target_language": language,
                    },
                    timeout=110,
                )
                response.raise_for_status()
                output = response.json()["output"]["translated_text"]
                if isinstance(output, str) and output.strip():
                    return key, output.strip()
            except (requests.RequestException, KeyError, TypeError, ValueError):
                if attempt == 7:
                    raise
                time.sleep(min(30, 2 ** attempt))
        raise RuntimeError(f"Could not translate {key}")

    checkpoint = OUTPUT_DIR / f"{language}.json"
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = [pool.submit(translate_one, entry) for entry in unchanged]
        for index, future in enumerate(as_completed(futures), start=1):
            key, value = future.result()
            translated[key] = value
            if index % 10 == 0:
                checkpoint.write_text(
                    json.dumps(translated, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )

    remaining = [
        key for key, _ in unchanged
        if translated.get(key, "").casefold() == source[key].casefold()
    ]
    if remaining:
        raise RuntimeError(f"Sunflower left English text in {language}: {remaining}")
    return translated


def translate_language(language: str, source: dict[str, str]) -> dict[str, str]:
    translated: dict[str, str] = {}
    initial = chunks(list(source.items()))
    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = [pool.submit(request_translation, language, chunk) for chunk in initial]
        for future in as_completed(futures):
            translated.update(future.result())

    missing = [(key, value) for key, value in source.items() if key not in translated]
    if missing:
        with ThreadPoolExecutor(max_workers=4) as pool:
            futures = [
                pool.submit(request_translation, language, chunk)
                for chunk in chunks(missing, limit=600)
            ]
            for future in as_completed(futures):
                translated.update(future.result())

    missing = [(key, value) for key, value in source.items() if key not in translated]
    for key, value in missing:
        response = requests.post(
            API_URL,
            json={"text": value.replace("\n", " "), "target_lang": language},
            timeout=110,
        )
        response.raise_for_status()
        output = response.json().get("translated_text")
        if isinstance(output, str) and output.strip():
            translated[key] = output.strip()

    if set(translated) != set(source):
        absent = sorted(set(source) - set(translated))
        raise RuntimeError(f"Incomplete {language} bundle: {absent}")
    return translated


def main() -> None:
    source = source_strings()
    if len(source) < 250:
        raise RuntimeError(f"Expected a complete UI catalog, found only {len(source)} entries")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for language in LANGUAGES:
        destination = OUTPUT_DIR / f"{language}.json"
        if destination.exists():
            existing = json.loads(destination.read_text(encoding="utf-8"))
            if set(existing) == set(source):
                translated = repair_unchanged(language, source, existing)
                destination.write_text(
                    json.dumps(translated, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )
                print(f"{language}: {len(translated)} verified and repaired strings")
                continue
        translated = translate_language(language, source)
        translated = repair_unchanged(language, source, translated)
        destination.write_text(
            json.dumps(translated, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"{language}: {len(translated)} strings -> {destination}")


if __name__ == "__main__":
    main()
