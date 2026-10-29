"""Content packs: reviewed lesson text a school keeps on its hub, which grounds
the hub's answers so the local model doesn't answer facts from memory.

A pack is one JSON file (any name ending in .json) in the packs folder:

    {
      "format": "otic-content-pack/1",
      "id": "sample-secondary",
      "title": "Sample secondary lessons",
      "version": "2026.10.23",
      "status": "draft",            # "reviewed" once a teacher has checked it
      "entries": [
        {"id": "geography.africa-location", "subject": "Geography",
         "level": "S3", "title": "Africa: Location, Relief and Drainage",
         "text": "...", "keyTerms": {"plateau": "..."}}
      ]
    }

A subject pack is a folder with its own pack.json, organised by topic, with
its pictures and clips beside it (see build_subject_pack.py):

    physics/pack.json      "topics": [...], "entries": [... "media": ["id"]],
                           "media": [{"id", "kind": "image"|"animation"|"clip",
                                      "file": "media/s1/...", "caption", "credit"}]
    physics/media/s1/measurements-in-physics/vernier-calipers-1.jpg

Search is by words (no model needed): the entries that best match the
question, and from each the sentences that do, within a size budget.
"""

from __future__ import annotations

import json
import logging
import math
import re
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

log = logging.getLogger("otic_cloud.packs")

FORMAT = "otic-content-pack/1"

#: The share of the question (weighted by how rare each word is) an entry
#: must contain to count as a match.
MIN_COVERAGE = 0.5

_POINTS_BACK = re.compile(r"\b(it|its|there|they|them|their|this|that|these|those|he|she|him|her)\b")

_TOPIC_FOLLOWUP = re.compile(
    r"^(?:please\s+)?(?:tell me more|explain more|explain further|go deeper|more detail|"
    r"expound(?: more)?|give me more context|(?:give|show) me (?:another|an?) example)"
    r"(?: please)?[.!?]*$", re.I,
)


def is_topic_followup(question: str) -> bool:
    return bool(_TOPIC_FOLLOWUP.fullmatch(question.strip()))


_STOP = set(
    """a an the and or of to in on at for from by with without is are was were be
    been being do does did what which who whom whose where when why how this that
    these those it its they them their there here i me my you your we us our he
    she him her his can could would should will shall may might must about into
    over under than then so as if not no yes please tell explain describe define
    show give some any more most very much many also just mean meant like know
    teach learn want need help example examples detail details detailed fully
    briefly brief expound context""".split()
)

def named_topic(question: str) -> str:
    """A definition/overview request's topic, preserving short words."""
    match = re.match(
        r"^(?:please\s+)?(?:can you\s+|could you\s+)?"
        r"(?:what\s+(?:is|are)|explain|describe|define|teach me(?: about)?|tell me about)\s+(.+)",
        question.strip().lower(),
    )
    if not match:
        return ""
    topic = re.sub(r"\b(?:in detail|more simply|fully|briefly|please)\b", " ", match[1])
    return " ".join(re.findall(r"[a-z0-9]+", topic)).strip()


def topic_in_text(topic: str, text: str) -> bool:
    return f" {topic} " in f" {' '.join(re.findall(r'[a-z0-9]+', text.lower()))} "


def entry_about_topic(entry: Entry, topic: str) -> bool:
    return set(words(topic)) <= entry._about or topic_in_text(topic, entry.title)


_SUFFIXES = ("ations", "ation", "ions", "ion", "ings", "ing", "ies", "ied", "ed", "es", "ic", "s", "e")


def _stem(w: str) -> str:
    """A rough word root, so "located", "location" and "locate" match, and
    "volcanoes", "volcanic" and "volcano" do."""
    for suffix in _SUFFIXES:
        if w.endswith(suffix) and len(w) - len(suffix) >= 4:
            if suffix == "s" and w.endswith("ss"):
                continue
            w = w[: -len(suffix)]
            break
    return w[:-1] if len(w) > 5 and w.endswith("o") else w


def words(text: str) -> list[str]:
    """Lower-case content words, as rough roots."""
    return [
        _stem(w)
        for w in re.findall(r"[a-z0-9]+", text.lower())
        if len(w) >= 2 and w not in _STOP
    ]


def _sentences(text: str) -> list[str]:
    parts = re.split(r"(?<=[.?!])\s+(?=[A-Z0-9\"'(])", text.strip())
    return [p.strip() for p in parts if p.strip()]


@dataclass
class Media:
    """A picture, animation or clip in a pack's folder."""

    id: str
    kind: str  # "image", "animation" or "clip"
    pack: str
    file: str  # relative to the pack's folder, e.g. "media/s1/heat-transfer/convection-1.png"
    caption: str = ""
    credit: str = ""
    poster: str | None = None  # a clip's still, relative like [file]
    seconds: int = 0
    topic: str = ""

    @property
    def is_clip(self) -> bool:
        return self.kind == "clip"


@dataclass
class Entry:
    id: str
    title: str
    text: str
    subject: str = ""
    level: str = ""
    key_terms: dict[str, str] = field(default_factory=dict)
    pack: str = ""
    reviewed: bool = False
    topic: str = ""
    media: list[Media] = field(default_factory=list)
    kind: str = ""  # "lesson" (the app's) or "reference"
    subtopic: str = ""

    def __post_init__(self) -> None:
        terms = " ".join(f"{k} {v}" for k, v in self.key_terms.items())
        self._counts = Counter(words(self.text) + words(terms))
        self._length = sum(self._counts.values())
        # What the entry is about: its title, and the names of its key terms.
        self._about = set(words(self.title)) | set(words(" ".join(self.key_terms)))


@dataclass
class Passage:
    entry: Entry
    text: str
    score: float


@dataclass
class Topic:
    """One topic of a subject pack (an app lesson), taught in parts (its
    sub-topics), in the order a teacher would."""

    id: str
    title: str
    parts: list[str]
    level: str = ""
    subject: str = ""
    pack: str = ""
    all_entries: list[Entry] = field(default_factory=list)

    @property
    def lessons(self) -> list[Entry]:
        return [e for e in self.all_entries if e.kind == "lesson"]

    def entries_for(self, part: str) -> list[Entry]:
        return [e for e in self.all_entries if e.subtopic == part]

    def part_index(self, text: str) -> int | None:
        """The part [text] names ("convection" → Convection), or None when it
        names the whole topic or no part."""
        asked = set(words(text))
        if not asked or asked <= set(words(self.title)):
            return None
        best, best_share = None, 0.0
        for i, part in enumerate(self.parts):
            own = set(words(part))
            if not own:
                continue
            share = len(asked & own) / len(own)
            if share > best_share:
                best, best_share = i, share
        return best if best_share >= 0.5 else None


def _topics_of(data: dict, pack: str, entries: list[Entry]) -> list[Topic]:
    by_id = {e.id: e for e in entries}
    out = []
    for raw in data.get("topics", []):
        if not isinstance(raw, dict) or not raw.get("id") or not raw.get("title"):
            continue
        out.append(
            Topic(
                id=str(raw["id"]),
                title=str(raw["title"]),
                parts=[str(p) for p in raw.get("subtopics", [])],
                level=str(raw.get("level", "")),
                subject=str(data.get("subject", "")),
                pack=pack,
                all_entries=[by_id[i] for i in raw.get("entries", []) if i in by_id],
            )
        )
    return out


def _entries_of(data: dict, pack: str) -> list[Entry]:
    """The entries of one pack file, each with its media."""
    media: dict[str, Media] = {}
    for raw in data.get("media", []):
        if not isinstance(raw, dict) or not raw.get("file") or not raw.get("id"):
            continue
        media[str(raw["id"])] = Media(
            id=str(raw["id"]),
            kind=str(raw.get("kind", "image")),
            pack=pack,
            file=str(raw["file"]),
            caption=str(raw.get("caption", "")),
            credit=str(raw.get("credit", "")),
            poster=raw.get("poster") or None,
            seconds=int(raw.get("seconds") or 0),
            topic=str(raw.get("topic", "")),
        )
    reviewed = data.get("status") == "reviewed"
    out = []
    for raw in data.get("entries", []):
        if not isinstance(raw, dict) or not raw.get("text"):
            continue
        out.append(
            Entry(
                id=str(raw.get("id", "")),
                title=str(raw.get("title", "")),
                text=str(raw["text"]),
                subject=str(raw.get("subject", "")),
                level=str(raw.get("level", "")),
                key_terms={str(k): str(v) for k, v in (raw.get("keyTerms") or {}).items()},
                pack=pack,
                reviewed=reviewed,
                topic=str(raw.get("topic", "")),
                media=[media[m] for m in raw.get("media", []) if m in media],
                kind=str(raw.get("kind", "")),
                subtopic=str(raw.get("subtopic", "")),
            )
        )
    return out


class PackLibrary:
    """Every entry of every pack in a folder, searchable."""

    def __init__(
        self,
        entries: list[Entry],
        folders: dict[str, Path] | None = None,
        topics: list[Topic] | None = None,
    ):
        self.entries = entries
        #: Each pack's folder, by pack id, for serving its media files.
        self.folders = folders or {}
        #: The topics of subject packs, in teaching order.
        self.topics = topics or []
        self._topic_by_id = {t.id: t for t in self.topics}
        self._df: Counter[str] = Counter()
        for e in entries:
            self._df.update(e._counts.keys())
        self._avg = (sum(e._length for e in entries) / len(entries)) if entries else 1.0
        self._by_topic: dict[str, list[Entry]] = {}
        for e in entries:
            if e.topic:
                self._by_topic.setdefault(e.topic, []).append(e)

    @classmethod
    def load(cls, folder: str | Path | None) -> "PackLibrary":
        """Every pack in [folder]: its *.json files, and the pack.json of each
        subject folder in it."""
        entries: list[Entry] = []
        folders: dict[str, Path] = {}
        topics: list[Topic] = []
        if folder:
            root = Path(folder)
            for path in sorted(root.glob("*.json")) + sorted(root.glob("*/pack.json")):
                try:
                    data = json.loads(path.read_text(encoding="utf-8"))
                except (OSError, ValueError) as e:
                    log.warning("Pack %s skipped: %s", path, e)
                    continue
                if not isinstance(data, dict) or data.get("format") != FORMAT:
                    continue
                pack = str(data.get("id", path.stem))
                folders[pack] = path.parent
                own = _entries_of(data, pack)
                entries += own
                topics += _topics_of(data, pack, own)
        return cls(entries, folders, topics)

    def topic_of(self, entry: Entry) -> Topic | None:
        return self._topic_by_id.get(entry.topic)

    def find_topic(self, text: str) -> Topic | None:
        """The topic [text] names: by its title, else the topic of the entry
        that best matches it (so "convection" finds Heat Transfer)."""
        if not self.topics:
            return None
        asked = text.strip().lower()
        for t in self.topics:
            if t.title.lower() == asked:
                return t
        asked_words = set(words(asked))
        if asked_words:
            for t in self.topics:
                if asked_words <= set(words(t.title)) or set(words(t.title)) <= asked_words:
                    return t
        for p in self.search(text, max_entries=3):
            topic = self.topic_of(p.entry)
            if topic is not None:
                return topic
        return None

    def next_topic(self, topic: Topic) -> Topic | None:
        """The topic taught after [topic] in its pack."""
        same = [t for t in self.topics if t.pack == topic.pack]
        i = same.index(topic) if topic in same else -1
        return same[i + 1] if 0 <= i < len(same) - 1 else None

    def media_file(self, pack: str, file: str) -> Path | None:
        """The file [file] of [pack]'s media folder, or None when there is no
        such pack or file, or [file] reaches outside the media folder."""
        folder = self.folders.get(pack)
        if folder is None:
            return None
        media = (folder / "media").resolve()
        path = (folder / file).resolve()
        if media not in path.parents or not path.is_file():
            return None
        return path

    def media_for(self, passages: list[Passage], clips: bool | None = None) -> list[Media]:
        """The media of the entries [passages] came from, then of the rest of
        their topics, best match first. [clips]: only clips (True), only
        pictures (False), or both (None)."""
        out: list[Media] = []
        seen: set[str] = set()

        def add(items: list[Media]) -> None:
            for m in items:
                if m.id not in seen and (clips is None or m.is_clip == clips):
                    seen.add(m.id)
                    out.append(m)

        for p in passages:
            add(p.entry.media)
        for p in passages:
            for e in self._by_topic.get(p.entry.topic, []):
                add(e.media)
        return out

    def _idf(self, w: str) -> float:
        n = len(self.entries)
        return math.log(1 + (n - self._df[w] + 0.5) / (self._df[w] + 0.5))

    def _score(self, entry: Entry, query: Counter[str]) -> float:
        """BM25 of [entry] for [query] (word -> weight), plus a bonus for words
        in its title or key terms."""
        score = 0.0
        for w, weight in query.items():
            idf = self._idf(w)
            tf = entry._counts.get(w, 0)
            if tf:
                norm = tf * 2.2 / (tf + 1.2 * (0.25 + 0.75 * entry._length / self._avg))
                score += weight * idf * norm
            if w in entry._about:
                score += weight * idf * 1.5
        return score

    def _coverage(self, entry: Entry, asked: set[str]) -> float:
        """How much of [asked] (weighted by how rare each word is) [entry]
        contains, from 0 to 1."""
        total = sum(self._idf(w) for w in asked)
        covered = sum(self._idf(w) for w in asked if w in entry._counts or w in entry._about)
        return covered / total if total else 0.0

    def search(
        self,
        question: str,
        context: str = "",
        max_entries: int = 2,
        budget: int = 2400,
    ) -> list[Passage]:
        """The best-matching passages for [question]; [context] (the learner's
        previous question) counts for less, so a follow-up ("why is it hot
        there?") still finds the topic under way."""
        asked = set(words(question))
        earlier = set(words(context))
        # "Why is it hot there?" is about the earlier question's topic.
        follow_up = bool(earlier) and (bool(_POINTS_BACK.search(question.lower())) or is_topic_followup(question))
        topic = named_topic(context if follow_up else question)
        query: Counter[str] = Counter()
        for w in asked:
            query[w] += 1.0
        for w in earlier:
            query[w] += 1.0 if follow_up else 0.4
        if not query or not self.entries:
            return []
        ranked = []
        for e in self.entries:
            if topic and len(words(topic)) > 1 and not (
                entry_about_topic(e, topic) or (
                    topic_in_text(topic, e.text) and (
                        len(re.findall(r"\b" + re.escape(topic) + r"\b", e.text.lower())) >= 2
                        or re.search(r"(?:^|[.!?]\s+)" + re.escape(topic) + r"\s+(?:is|are|means|refers)\b", e.text.lower())
                    )
                )
                or any(topic_in_text(topic, key) for key in e.key_terms)
            ):
                continue
            score = self._score(e, query)
            # Matching only the question's common words ("what causes
            # inflation" → a lesson that says "causes") is no match; a
            # follow-up may match through the earlier question instead.
            if score > 0 and (
                self._coverage(e, asked) >= MIN_COVERAGE
                or (follow_up and self._coverage(e, earlier) >= MIN_COVERAGE)
            ):
                ranked.append((score, e))
        if not ranked:
            return []
        ranked.sort(key=lambda pair: pair[0], reverse=True)
        best = ranked[0][0]
        out: list[Passage] = []
        left = budget
        for score, entry in ranked[:max_entries]:
            # A second entry only when it is nearly as good a match.
            if score < best * 0.6 or left < 300:
                break
            text = self._excerpt(entry, query, left)
            out.append(Passage(entry=entry, text=text, score=score))
            left -= len(text)
        return out

    @staticmethod
    def _excerpt(entry: Entry, query: Counter[str], budget: int) -> str:
        """The sentences of [entry] that match [query], each with the one
        after it (the lessons ask a question, then answer it), in order."""
        sentences = _sentences(entry.text)
        if sum(len(s) + 1 for s in sentences) <= budget:
            return entry.text.strip()
        scored = []
        for i, s in enumerate(sentences):
            hits = sum(query.get(w, 0) for w in set(words(s)))
            if hits:
                scored.append((hits, i))
        scored.sort(key=lambda p: (-p[0], p[1]))
        keep: set[int] = set()
        size = 0
        for _, i in scored:
            for j in (i, i + 1):
                if j < len(sentences) and j not in keep and size + len(sentences[j]) + 1 <= budget:
                    keep.add(j)
                    size += len(sentences[j]) + 1
        if not keep:
            keep = {0}
        return " ".join(sentences[j] for j in sorted(keep))
