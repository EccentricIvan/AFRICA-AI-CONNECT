"""Builds a sample content pack from the app's built-in lessons, for trying the
school hub before the national curriculum's reviewed packs exist.

    .venv\\Scripts\\python -m otic_cloud.build_pack ..\\assets "D:\\data packets\\sample-secondary.json"

The pack is marked "draft": its text is the app's own lessons, not yet checked
by a teacher for this purpose.
"""

from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path

from .packs import FORMAT


def _slug(text: str) -> str:
    return "-".join("".join(c if c.isalnum() else " " for c in text.lower()).split())[:60]


def lesson_entries(assets: Path, skip: frozenset[str] = frozenset()) -> list[dict]:
    """One entry per curriculum lesson: its text and worked examples. Subjects
    in [skip] have a pack of their own."""
    out = []
    for path in sorted((assets / "curriculum").glob("*.json")):
        if path.stem in skip:
            continue
        subject = json.loads(path.read_text(encoding="utf-8"))
        for unit in subject.get("units", []):
            for lesson in unit.get("lessons", []):
                examples = [e for e in lesson.get("examples", []) if isinstance(e, str)]
                text = lesson.get("content", "").strip()
                if examples:
                    text += "\n\nWorked examples:\n" + "\n\n".join(examples)
                out.append(
                    {
                        "id": f"{subject['id']}.{_slug(lesson['title'])}",
                        "subject": subject.get("name", subject["id"]),
                        "level": unit.get("title", ""),
                        "title": lesson["title"],
                        "text": text,
                        "keyTerms": lesson.get("keyTerms") or {},
                    }
                )
    return out


def explanation_entries(assets: Path) -> list[dict]:
    """One entry per full topic explanation: its summary and sections."""
    out = []
    for path in sorted((assets / "topic_explanations").glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict) or "topics" not in data:
            continue
        for topic in data["topics"]:
            sections = "\n\n".join(
                f"{s.get('heading', '')}: {s.get('body', '')}" for s in topic.get("sections", [])
            )
            out.append(
                {
                    "id": topic["id"],
                    "subject": data.get("subject", ""),
                    "level": topic.get("level", ""),
                    "title": topic["title"],
                    "text": f"{topic.get('summary', '')}\n\n{sections}".strip(),
                    "keyTerms": topic.get("keyTerms") or {},
                }
            )
    return out


def build(assets: Path, skip: frozenset[str] = frozenset()) -> dict:
    entries = [
        e for e in explanation_entries(assets) if e["id"].split(".")[0] not in skip
    ] + lesson_entries(assets, skip)
    return {
        "format": FORMAT,
        "id": "sample-secondary",
        "title": "Sample secondary lessons (from the app's built-in curriculum)",
        "version": date.today().isoformat(),
        "status": "draft",
        "entries": entries,
    }


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__)
        return 2
    out = Path(argv[1])
    # A subject with its own pack folder beside this one ("physics/pack.json")
    # is left out, so its lessons aren't found twice.
    skip = frozenset(p.parent.name for p in out.parent.glob("*/pack.json"))
    pack = build(Path(argv[0]), skip)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(pack, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(pack['entries'])} entries -> {out}" + (f" (left out: {', '.join(sorted(skip))})" if skip else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
