"""Builds one subject's content pack, organised by class and topic, with
reference text, pictures and clips, for the school hub.

    .venv\\Scripts\\python -m otic_cloud.build_subject_pack physics ..\\assets "D:\\data packets\\physics"

For each of the app's lessons in the subject (a topic), and each sub-topic
listed for it in pack_sources/<subject>.json:

- the app's lesson, worked examples and practice questions;
- the reference text of the sub-topic's Wikipedia article (introduction and
  main sections), credited, CC BY-SA;
- freely licensed pictures, animations and short clips from that article and
  Wikimedia Commons, downloaded into media/<class>/<topic>/, each credited.

Everything is saved as it arrives, so a dropped connection loses nothing: run
it again and it carries on. The pack is a "draft" until a teacher reviews it.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
import time
from datetime import date
from pathlib import Path

import httpx

from .packs import FORMAT

# Wikimedia's robot policy wants a name, a contact address and the library.
UA = "AIConnectAfrica-PackBuilder/1.0 (https://github.com/EccentricIvan/AI-CONNECT-AFRICA) python-httpx"
WIKI = "https://en.wikipedia.org/w/api.php"
COMMONS = "https://commons.wikimedia.org/w/api.php"

#: Per sub-topic and per topic, so a pack stays small enough for one hub.
PICTURES_PER_SUBTOPIC = 3
CLIPS_PER_TOPIC = 2
MAX_REFERENCE_CHARS = 6000
MAX_PICTURE_BYTES = 4 * 1024 * 1024
MAX_CLIP_BYTES = 30 * 1024 * 1024
MAX_CLIP_SECONDS = 300
#: Shorter clips are mostly loops from research papers, too quick to teach.
MIN_CLIP_SECONDS = 10

#: Videos published with research papers: data, not teaching.
_RESEARCH_DATA = re.compile(r"(ncomms|plos|journal|supplement|visualization-data|-data-|\bdoi\b|\d{5,})", re.I)

_SKIP_SECTIONS = re.compile(
    r"^(see also|references|notes|further reading|external links|bibliography|"
    r"citations|sources|footnotes|gallery|explanatory notes)$",
    re.I,
)
_FREE = re.compile(r"public domain|cc0|cc by", re.I)
_NOT_FREE = re.compile(r"\bnc\b|\bnd\b", re.I)
_FURNITURE = re.compile(
    r"(icon|logo|symbol|flag_of|flag of|commons-|wiki|edit-|question_book|ambox|padlock|"
    r"disambig|stub|portal|nuvola|crystal_clear|gnome-|emblem|signature|\.pdf$|\.tif)",
    re.I,
)
_UNSUITABLE = re.compile(
    r"(^|[\W_])(nude|nudity|naked|sex|sexual|genitals?|penis|vagina|vulva|breasts?|"
    r"porn\w*|erotic\w*|corpses?|dead|gore|wounds?|weapon\w*|bomb\w*|explosion\w*)([\W_]|$)",
    re.I,
)
#: Not about the topic, even when named after it.
_OFF_TOPIC = re.compile(
    r"(signature|autograph|portrait|stamp|postage|coin|banknote|memorial|grave|statue|"
    r"bust_of|bust of|headshot|plaque|book cover|cover of|lever[-_ ]soleil|salvia[-_ ])",
    re.I,
)
_COMMON = {
    "with", "from", "that", "this", "their", "about", "what", "the", "and", "for", "how",
    "physics", "physical", "science", "theory", "law", "laws", "effect", "effects",
}


def short_hash(text: str) -> str:
    """Six characters naming a source file, so a rebuild reuses each download
    only for the same picture or clip."""
    return hashlib.sha1(text.encode()).hexdigest()[:6]


def slug(text: str, n: int = 50) -> str:
    return "-".join(re.sub(r"[^a-z0-9]+", " ", text.lower()).split())[:n].strip("-")


def key_words(*texts: str) -> set[str]:
    """The words that say what a topic is ("Brownian motion" -> brownian,
    motion), plurals folded; not the words every physics page has."""
    out = set()
    for t in texts:
        for w in re.findall(r"[a-z]+", re.sub(r"\(.*?\)", "", t.lower())):
            if len(w) >= 4 and w not in _COMMON:
                out.add(w[:-1] if len(w) > 4 and w.endswith("s") and not w.endswith("ss") else w)
    return out


def names_all(text: str, words: set[str]) -> bool:
    text = text.lower()
    return bool(words) and words <= key_words(text)


def names_any(text: str, words: set[str]) -> bool:
    text = text.lower()
    return any(w in text for w in words)


def clean_html(s: str) -> str:
    s = re.sub(r"<[^>]+>", "", s or "")
    for a, b in (("&amp;", "&"), ("&quot;", '"'), ("&#39;", "'"), ("&nbsp;", " "), ("&lt;", "<"), ("&gt;", ">")):
        s = s.replace(a, b)
    return re.sub(r"\s+", " ", s).strip()


class Fetcher:
    """GETs with a polite user agent, retries for a flaky connection, and a
    cache of API answers on disk so a rerun asks nothing twice."""

    def __init__(self, cache: Path):
        self.cache = cache
        cache.mkdir(parents=True, exist_ok=True)
        self.client = httpx.Client(headers={"User-Agent": UA}, timeout=60, follow_redirects=True)

    def json(self, url: str, params: dict) -> dict:
        key = hashlib.sha1((url + json.dumps(params, sort_keys=True)).encode()).hexdigest()
        path = self.cache / f"{key}.json"
        if path.exists():
            return json.loads(path.read_text(encoding="utf-8"))
        data = json.loads(self._get(url, {**params, "format": "json", "formatversion": "2"}))
        path.write_text(json.dumps(data), encoding="utf-8")
        return data

    def download(self, url: str, dest: Path, max_bytes: int) -> bool:
        if dest.exists() and dest.stat().st_size > 0:
            return True
        dest.parent.mkdir(parents=True, exist_ok=True)
        part = dest.with_suffix(dest.suffix + ".part")
        for attempt in range(6):
            try:
                with self.client.stream("GET", url) as r:
                    if r.status_code == 429:
                        time.sleep(30)
                        continue
                    r.raise_for_status()
                    size = int(r.headers.get("content-length") or 0)
                    if size > max_bytes:
                        return False
                    got = 0
                    with open(part, "wb") as f:
                        for chunk in r.iter_bytes(65536):
                            got += len(chunk)
                            if got > max_bytes:
                                break
                            f.write(chunk)
                if got > max_bytes:
                    part.unlink(missing_ok=True)
                    return False
                part.replace(dest)
                return True
            except httpx.HTTPError as e:
                print(f"    retry {attempt + 1} for {dest.name}: {e}", flush=True)
                time.sleep(5 * (attempt + 1))
        part.unlink(missing_ok=True)
        return False

    def _get(self, url: str, params: dict) -> str:
        for attempt in range(6):
            try:
                r = self.client.get(url, params=params)
                if r.status_code == 429:
                    time.sleep(30)
                    continue
                r.raise_for_status()
                return r.text
            except httpx.HTTPError as e:
                print(f"    retry {attempt + 1}: {e}", flush=True)
                time.sleep(5 * (attempt + 1))
        raise RuntimeError(f"gave up on {url} {params}")


def reference_text(f: Fetcher, article: str) -> tuple[str, str, int] | None:
    """The article's introduction and main sections (plain text, headings
    kept), its resolved title and revision."""
    data = f.json(WIKI, {
        "action": "query", "prop": "extracts|info", "titles": article, "redirects": "1",
        "explaintext": "1", "exsectionformat": "wiki",
    })
    pages = data.get("query", {}).get("pages", [])
    if not pages or pages[0].get("missing") or not pages[0].get("extract"):
        return None
    page = pages[0]
    out, size = [], 0
    for i, part in enumerate(re.split(r"\n(?===+ )", page["extract"])):
        heading = re.match(r"=+ (.+?) =+", part)
        if heading and _SKIP_SECTIONS.match(heading.group(1).strip()):
            continue
        part = re.sub(r"\n{3,}", "\n\n", part).strip()
        if heading:
            part = re.sub(r"^=+ (.+?) =+", lambda m: f"{m.group(1).strip()}:", part)
        if not part or (heading and len(part) < len(heading.group(0)) + 40):
            continue
        if size + len(part) > MAX_REFERENCE_CHARS:
            if i == 0:
                out.append(part[:MAX_REFERENCE_CHARS].rsplit(". ", 1)[0] + ".")
            break
        out.append(part)
        size += len(part)
    return "\n\n".join(out), page["title"], int(page.get("lastrevid", 0))


def _article_files(f: Fetcher, title: str) -> list[dict]:
    data = f.json(WIKI, {
        "action": "query", "generator": "images", "titles": title, "gimlimit": "50",
        "prop": "imageinfo", "iiprop": "url|mime|size|extmetadata", "iiurlwidth": "800",
    })
    return data.get("query", {}).get("pages", [])


def article_pictures(f: Fetcher, title: str, label: str) -> list[dict]:
    """Freely licensed pictures and animations of the article: its lead
    picture, then those whose name or caption has the sub-topic's key words."""
    lead = f.json(WIKI, {"action": "query", "prop": "pageimages", "titles": title, "piprop": "name"})
    lead_name = ((lead.get("query", {}).get("pages") or [{}])[0].get("pageimage") or "").replace("_", " ")
    want = key_words(title, label)
    out = []
    for page in _article_files(f, title):
        name = page.get("title", "").removeprefix("File:")
        info = (page.get("imageinfo") or [None])[0]
        if not info or _FURNITURE.search(name) or _UNSUITABLE.search(name) or _OFF_TOPIC.search(name):
            continue
        mime = info.get("mime", "")
        if mime not in ("image/jpeg", "image/png", "image/svg+xml", "image/gif"):
            continue
        if (info.get("width") or 0) < 300:
            continue
        meta = info.get("extmetadata") or {}
        lic = clean_html((meta.get("LicenseShortName") or {}).get("value", ""))
        if not _FREE.search(lic) or _NOT_FREE.search(lic):
            continue
        caption = clean_html((meta.get("ImageDescription") or {}).get("value", ""))
        if _UNSUITABLE.search(caption) or _OFF_TOPIC.search(caption[:80]):
            continue
        is_lead = name == lead_name
        if not is_lead and not names_any(f"{name} {caption}", want):
            continue
        animated = mime == "image/gif"
        if animated:
            if (info.get("size") or 1 << 30) > MAX_PICTURE_BYTES:
                continue
            url = info["url"]  # a thumbnail of a GIF may lose its animation
        else:
            url = info.get("thumburl") or info["url"]  # an SVG's thumbnail is a PNG
        artist = clean_html((meta.get("Artist") or {}).get("value", "")) or "Wikimedia Commons contributors"
        out.append({
            "kind": "animation" if animated else "image",
            "url": url,
            "name": name,
            "caption": caption[:200] if caption else re.sub(r"\.\w+$", "", name).replace("_", " "),
            "credit": f"{artist[:120]}, {lic}, via Wikimedia Commons",
            "licence": lic,
            "source": info.get("descriptionurl", ""),
            "lead": is_lead,
        })
    out.sort(key=lambda p: (not p["lead"], p["kind"] == "animation"))
    return out


def article_clips(f: Fetcher, title: str, label: str = "") -> list[dict]:
    """Require a clip to name the sub-topic, not merely appear in its article."""
    require = key_words(title, label)
    if not require:
        return []
    names = [
        p["title"] for p in _article_files(f, title)
        if (p.get("imageinfo") or [{}])[0].get("mime", "").startswith(("video/", "application/ogg"))
    ]
    if not names:
        return []
    data = f.json(COMMONS, {
        "action": "query", "titles": "|".join(names[:20]),
        "prop": "videoinfo", "viprop": "url|mime|size|extmetadata|derivatives", "viurlwidth": "640",
    })
    return _clips_of(data.get("query", {}).get("pages", []), require=require)


def commons_clips(f: Fetcher, query: str, label: str = "") -> list[dict]:
    """Short, freely licensed videos on Wikimedia Commons whose file name has
    every key word of [query] and of the sub-topic's [label] ("Micrometer
    screw gauge": micrometer, screw and gauge)."""
    data = f.json(COMMONS, {
        "action": "query", "generator": "search", "gsrnamespace": "6",
        "gsrsearch": f"{query} filetype:video", "gsrlimit": "15",
        "prop": "videoinfo", "viprop": "url|mime|size|extmetadata|derivatives", "viurlwidth": "640",
    })
    pages = sorted(data.get("query", {}).get("pages", []), key=lambda p: p.get("index", 0))
    return _clips_of(pages, require=key_words(query) | key_words(label))


def _clips_of(pages: list[dict], require: set[str]) -> list[dict]:
    out = []
    for page in pages:
        name = page.get("title", "").removeprefix("File:")
        info = (page.get("videoinfo") or [None])[0]
        if not info or info.get("mime", "").startswith("audio/") or _UNSUITABLE.search(name) or _OFF_TOPIC.search(name):
            continue
        if require and not names_all(name.replace("_", " "), require):
            continue
        if _RESEARCH_DATA.search(name):
            continue
        seconds = float(info.get("duration") or 0)
        if not MIN_CLIP_SECONDS <= seconds <= MAX_CLIP_SECONDS:
            continue
        meta = info.get("extmetadata") or {}
        lic = clean_html((meta.get("LicenseShortName") or {}).get("value", ""))
        if not _FREE.search(lic) or _NOT_FREE.search(lic):
            continue
        caption = clean_html((meta.get("ImageDescription") or {}).get("value", ""))
        if _UNSUITABLE.search(caption):
            continue
        webm = sorted(
            (d for d in info.get("derivatives") or [] if d.get("type", "").startswith("video/webm") and 360 <= (d.get("height") or 0) <= 480),
            key=lambda d: d.get("height", 0),
        )
        src = webm[0]["src"] if webm else (info["url"] if (info.get("size") or 1 << 30) <= MAX_CLIP_BYTES else None)
        if not src:
            continue
        artist = clean_html((meta.get("Artist") or {}).get("value", "")) or "Wikimedia Commons contributors"
        out.append({
            "kind": "clip",
            "url": src,
            "poster": info.get("thumburl"),
            "name": name,
            "seconds": round(seconds),
            "caption": caption[:200] if caption else re.sub(r"\.\w+$", "", name).replace("_", " "),
            "credit": f"{artist[:120]}, {lic}, via Wikimedia Commons",
            "licence": lic,
            "source": info.get("descriptionurl", ""),
        })
    return out


def selected_clips(source: dict, topic: str, candidates: list[dict]) -> list[dict]:
    """A curated subject never silently admits new search results on rebuild."""
    if 'clip_allowlist' not in source:
        return candidates
    allowed = set(source['clip_allowlist'].get(topic, []))
    return [c for c in candidates if c['name'] in allowed]


def lesson_text(lesson: dict) -> str:
    parts = [lesson.get("content", "").strip()]
    examples = [e for e in lesson.get("examples", []) if isinstance(e, str)]
    if examples:
        parts.append("Worked examples:\n" + "\n\n".join(examples))
    quiz = []
    for q in lesson.get("quiz", []):
        try:
            answer = q["options"][q["correct"]]
        except (KeyError, IndexError, TypeError):
            continue
        quiz.append(f"Q: {q['question']}\nAnswer: {answer}. {q.get('explanation', '')}".strip())
    if quiz:
        parts.append("Practice questions:\n" + "\n\n".join(quiz))
    return "\n\n".join(parts)


def ext_of(url: str, default: str) -> str:
    m = re.search(r"\.(jpe?g|png|gif|webm|ogv)(?:$|\?)", url.split("?")[0].lower())
    return "." + (m.group(1) if m else default)


def build(subject_id: str, assets: Path, out: Path) -> dict:
    source = json.loads((Path(__file__).parent / "pack_sources" / f"{subject_id}.json").read_text(encoding="utf-8"))
    subject = json.loads((assets / "curriculum" / f"{subject_id}.json").read_text(encoding="utf-8"))
    f = Fetcher(out / ".cache")
    topics, entries, media = [], [], []
    missing = []

    for unit in subject["units"]:
        level = unit["title"]
        for lesson in unit["lessons"]:
            title = lesson["title"]
            tid = f"{subject_id}.{level.lower()}.{slug(title, 40)}"
            folder = Path("media") / level.lower() / slug(title, 40)
            subs = source["topics"].get(title)
            if subs is None:
                missing.append(title)
                subs = []
            print(f"{level} | {title}", flush=True)
            topic = {"id": tid, "level": level, "title": title, "subtopics": [s[0] for s in subs], "entries": [], "media": []}

            lesson_id = f"{tid}.lesson"
            entries.append({
                "id": lesson_id, "topic": tid, "kind": "lesson", "subject": subject["name"], "level": level,
                "title": title, "text": lesson_text(lesson), "keyTerms": lesson.get("keyTerms") or {},
                "source": {"title": "AI Connect Africa built-in lesson", "licence": "app content"},
                "media": [],
            })
            topic["entries"].append(lesson_id)

            for label, article in subs:
                ref = reference_text(f, article)
                if ref is None:
                    print(f"  ! no article for {label!r} ({article})", flush=True)
                    continue
                text, resolved, revid = ref
                eid = f"{tid}.{slug(label, 40)}"
                entry_media = []
                for n, pic in enumerate(article_pictures(f, resolved, label)[:PICTURES_PER_SUBTOPIC], 1):
                    if f"{eid}|{pic['source']}" in source.get("excluded_media_sources", {}):
                        continue
                    rel = folder / f"{slug(label, 30)}-{short_hash(pic['name'])}{ext_of(pic['url'], 'png')}"
                    if not f.download(pic["url"], out / rel, MAX_PICTURE_BYTES):
                        continue
                    mid = f"{eid}.m{n}"
                    media.append({
                        "id": mid, "topic": tid, "entry": eid, "kind": pic["kind"], "file": rel.as_posix(),
                        "caption": pic["caption"], "credit": pic["credit"], "licence": pic["licence"], "source": pic["source"],
                    })
                    entry_media.append(mid)
                entries.append({
                    "id": eid, "topic": tid, "kind": "reference", "subject": subject["name"], "level": level,
                    "title": f"{label} ({title})", "subtopic": label, "text": text, "keyTerms": {},
                    "source": {
                        "title": f"Wikipedia: {resolved}",
                        "url": f"https://en.wikipedia.org/w/index.php?title={resolved.replace(' ', '_')}&oldid={revid}",
                        "licence": "CC BY-SA 4.0",
                        "credit": f"Wikipedia contributors, \"{resolved}\", CC BY-SA 4.0",
                    },
                    "media": entry_media,
                })
                topic["entries"].append(eid)
                topic["media"].extend(entry_media)
                print(f"  + {label}: {len(text)} chars, {len(entry_media)} pictures", flush=True)

            # Curated subjects query only named files, never broad searches.
            if 'clip_allowlist' in source:
                approved = source['clip_allowlist'].get(title, [])
                candidates = []
                if approved:
                    data = f.json(COMMONS, {
                        'action': 'query', 'titles': '|'.join('File:' + n for n in approved),
                        'prop': 'videoinfo', 'viprop': 'url|mime|size|extmetadata|derivatives',
                        'viurlwidth': '640',
                    })
                    candidates = _clips_of(data.get('query', {}).get('pages', []), require=set())
            else:
                # The articles' own videos first (their editors chose them), then
                # Commons files named after a sub-topic.
                resolved_titles = {e["subtopic"]: e["source"]["title"].removeprefix("Wikipedia: ")
                                   for e in entries if e.get("topic") == tid and e["kind"] == "reference"}
                candidates = [c for label, _ in subs if label in resolved_titles
                              for c in article_clips(f, resolved_titles[label], label)]
                candidates += [c for label, article in subs for c in commons_clips(f, article, label)]
            candidates = selected_clips(source, title, candidates)
            clips, seen = [], set()
            for clip in candidates:
                if len(clips) >= CLIPS_PER_TOPIC:
                    break
                if clip["name"] in seen:
                    continue
                seen.add(clip["name"])
                n = len(clips) + 1
                stem = f"clip-{short_hash(clip['name'])}"
                rel = folder / f"{stem}{ext_of(clip['url'], 'webm')}"
                if not f.download(clip["url"], out / rel, MAX_CLIP_BYTES):
                    continue
                poster = None
                if clip["poster"]:
                    prel = folder / f"{stem}{ext_of(clip['poster'], 'jpg')}"
                    if f.download(clip["poster"], out / prel, MAX_PICTURE_BYTES):
                        poster = prel.as_posix()
                mid = f"{tid}.clip{n}"
                media.append({
                    "id": mid, "topic": tid, "entry": lesson_id, "kind": "clip", "file": rel.as_posix(),
                    "poster": poster, "seconds": clip["seconds"], "caption": clip["caption"],
                    "credit": clip["credit"], "licence": clip["licence"], "source": clip["source"],
                })
                clips.append(mid)
                print(f"  > clip {n}: {clip['name']} ({clip['seconds']} s)", flush=True)
            entries[[e["id"] for e in entries].index(lesson_id)]["media"] = clips
            topic["media"].extend(clips)
            topics.append(topic)

    if missing:
        print(f"Lessons with no sub-topics listed: {missing}", flush=True)
    return {
        "format": FORMAT,
        "id": subject_id,
        "title": source["title"],
        "subject": subject["name"],
        "version": date.today().isoformat(),
        "status": "draft",
        "topics": topics,
        "entries": entries,
        "media": media,
    }


def credits(pack: dict) -> str:
    lines = [
        f"# Credits: {pack['title']}",
        "",
        "Lesson text: AI Connect Africa. Reference text: Wikipedia contributors, CC BY-SA 4.0",
        "(https://creativecommons.org/licenses/by-sa/4.0/); shared under the same licence.",
        "Pictures and clips: Wikimedia Commons, each under the licence named below.",
        "",
        "## Reference text",
        "",
    ]
    lines += [f"- {e['source']['title']} - {e['source']['url']}" for e in pack["entries"] if e["kind"] == "reference"]
    lines += ["", "## Pictures and clips", ""]
    lines += [f"- {m['file']}: {m['credit']} - {m['source']}" for m in pack["media"]]
    return "\n".join(lines) + "\n"


def readme(pack: dict) -> str:
    """A contents page for whoever opens the pack's folder: every class and
    topic, with its sub-topics and how many pictures and clips it has."""
    kinds = {m["id"]: m["kind"] for m in pack["media"]}
    lines = [
        pack["title"],
        "=" * len(pack["title"]),
        "",
        f"Version {pack['version']} - status: {pack['status'].upper()} (not yet reviewed by a teacher)",
        "",
        "pack.json    every topic, its text (the app's lesson + reference text) and its media",
        "media/       pictures, animations and clips, in a folder per class and topic",
        "CREDITS.md   the author and licence of every text, picture and clip",
        "",
    ]
    level = None
    for t in pack["topics"]:
        if t["level"] != level:
            level = t["level"]
            lines += ["", level, "-" * len(level)]
        pics = sum(kinds.get(m) in ("image", "animation") for m in t["media"])
        clips = sum(kinds.get(m) == "clip" for m in t["media"])
        lines.append(f"{t['title']}  ({pics} pictures, {clips} clips)")
        lines += [f"    - {s}" for s in t["subtopics"]]
    return "\n".join(lines) + "\n"


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__)
        return 2
    subject_id, assets, out = argv[0], Path(argv[1]), Path(argv[2])
    pack = build(subject_id, assets, out)
    (out / "pack.json").write_text(json.dumps(pack, ensure_ascii=False, indent=1), encoding="utf-8")
    (out / "CREDITS.md").write_text(credits(pack), encoding="utf-8")
    (out / "README.txt").write_text(readme(pack), encoding="utf-8")
    # Preserve unused downloads outside the served media tree for audit/recovery.
    used = {m["file"] for m in pack["media"]} | {m["poster"] for m in pack["media"] if m.get("poster")}
    for path in (out / "media").rglob("*") if (out / "media").exists() else []:
        if path.is_file() and path.relative_to(out).as_posix() not in used:
            archived = out / "_unused-media" / path.relative_to(out / "media")
            archived.parent.mkdir(parents=True, exist_ok=True)
            path.replace(archived)
    size = sum(p.stat().st_size for p in (out / "media").rglob("*") if p.is_file()) if (out / "media").exists() else 0
    kinds = {k: sum(m["kind"] == k for m in pack["media"]) for k in ("image", "animation", "clip")}
    print(
        f"DONE {len(pack['topics'])} topics, {len(pack['entries'])} entries, "
        f"{kinds['image']} pictures, {kinds['animation']} animations, {kinds['clip']} clips, "
        f"{size / 1024 / 1024:.0f} MB of media -> {out}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
