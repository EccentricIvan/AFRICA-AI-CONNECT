"""Teaching a whole topic, part by part, the way a teacher would: the plan
first, then one sub-topic per turn, each ending with a check question, and
suggestions for what to do next.

Stateless: where the learner is comes from the conversation itself. Each part
starts with a heading the next turn can read back ("**Heat Transfer — Part 2
of 4: Convection**"), and the suggestions name the part they lead to ("Next:
Radiation (Heat Transfer)").
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from .packs import Entry, PackLibrary, Topic

_START = re.compile(
    r"^(?:please\s+)?(?:can you\s+|could you\s+)?"
    r"(?:teach me|i want to learn|help me (?:to )?learn|let'?s learn|take me through|walk me through|"
    r"give me a (?:full )?lesson on|start (?:the |a )?(?:topic|lesson|course)(?: on)?)"
    r"(?:\s+(?:all\s+)?about)?\s+(?P<what>.+?)[.!?]*$",
    re.I,
)
_NEXT = re.compile(r"^(?:next|continue|go on|carry on|move on|next part|keep going|ok next|okay next)\b", re.I)
_NEXT_NAMED = re.compile(r"^next(?: part)?:\s*(?P<part>.+?)\s*\((?P<topic>.+)\)\s*$", re.I)
_NEXT_TOPIC = re.compile(r"^next topic:\s*(?P<topic>.+?)\s*$", re.I)
_QUIZ = re.compile(r"^(?:please\s+)?(?:quiz me|test me|give me (?:a )?(?:quiz|questions))(?:\s+on(?: all of)?\s+(?P<what>.+?))?[.!?]*$", re.I)
_SUMMARY = re.compile(r"^(?:please\s+)?(?:summari[sz]e|give me a summary of|sum up)\s+(?P<what>.+?)[.!?]*$", re.I)
_HEADING = re.compile(r"\*\*(?P<topic>.+?) — Part (?P<k>\d+) of (?P<n>\d+): (?P<part>.+?)\*\*")


@dataclass
class Step:
    """What this turn should do."""

    kind: str  # "part", "quiz" or "summary"
    topic: Topic
    part: int = 0  # index into topic.parts, for kind == "part"
    show_plan: bool = False


def plan_step(library: PackLibrary, message: str, history_texts: list[str]) -> Step | None:
    """The course step [message] asks for, or None when it is an ordinary
    question. [history_texts] are the tutor's earlier replies, newest last."""
    text = message.strip()

    m = _NEXT_NAMED.match(text)
    if m:
        topic = library.find_topic(m.group("topic"))
        if topic:
            i = topic.part_index(m.group("part"))
            if i is not None:
                return Step("part", topic, i)

    m = _NEXT_TOPIC.match(text)
    if m:
        topic = library.find_topic(m.group("topic"))
        if topic:
            return Step("part", topic, 0, show_plan=True)

    if _NEXT.match(text) and len(text) < 40:
        for reply in reversed(history_texts):
            h = _HEADING.search(reply)
            if not h:
                continue
            topic = library.find_topic(h.group("topic"))
            if topic is None:
                break
            k = int(h.group("k"))
            if k < len(topic.parts):
                return Step("part", topic, k)
            return Step("summary", topic)
        return None

    m = _QUIZ.match(text)
    if m:
        what = m.group("what") or _last_topic_title(history_texts) or ""
        topic = library.find_topic(what) if what else None
        if topic:
            return Step("quiz", topic, topic.part_index(what) or 0)
        return None

    m = _SUMMARY.match(text)
    if m:
        topic = library.find_topic(m.group("what"))
        if topic:
            return Step("summary", topic)
        return None

    m = _START.match(text)
    if m:
        what = m.group("what")
        topic = library.find_topic(what)
        if topic:
            # "Teach me convection" starts at that part; the topic's own name
            # starts at the beginning.
            i = topic.part_index(what)
            return Step("part", topic, i or 0, show_plan=True)
    return None


def _last_topic_title(history_texts: list[str]) -> str | None:
    for reply in reversed(history_texts):
        h = _HEADING.search(reply)
        if h:
            return h.group("topic")
    return None


def heading(topic: Topic, i: int) -> str:
    return f"**{topic.title} — Part {i + 1} of {len(topic.parts)}: {topic.parts[i]}**"


def plan_text(topic: Topic, start: int) -> str:
    """The course plan shown when a topic starts."""
    lines = [f"Let's learn **{topic.title}** ({topic.subject} {topic.level}). We'll go through it in "
             f"{len(topic.parts)} parts:", ""]
    for i, part in enumerate(topic.parts):
        mark = " ← we start here" if i == start and start > 0 else ""
        lines.append(f"{i + 1}. {part}{mark}")
    lines += ["", "Tap **Next** when you're ready for each part, or ask me anything on the way."]
    return "\n".join(lines)


def instruction(step: Step) -> str:
    """What the model is asked to write for [step]."""
    t = step.topic
    if step.kind == "part":
        part = t.parts[step.part]
        return (
            f"You are teaching the topic \"{t.title}\" ({t.subject}, {t.level}) part by part. "
            f"This turn, teach ONLY part {step.part + 1} of {len(t.parts)}: \"{part}\". "
            "Teach it fully, as a good teacher would in one lesson segment:\n"
            "1. Start straight with the idea in one or two plain sentences (no greeting, no heading).\n"
            "2. Explain how it works step by step, in short paragraphs, with **key terms in bold** "
            "and what each one means.\n"
            "3. Give a concrete everyday example from Uganda or East Africa and explain why it fits.\n"
            "4. If the idea has a formula or calculation, give the formula with its units and one short "
            "worked example.\n"
            "5. Explain why this idea matters, a common misconception, and a short recap.\n"
            "6. End with ONE short check question for the learner (do not answer it).\n"
            "Use the FACTS; do not teach the other parts yet. About 400 to 650 useful words with meaningful subheadings."
        )
    if step.kind == "quiz":
        return (
            f"Give the learner a short quiz on \"{t.title}\" ({t.subject}, {t.level}): 4 questions, "
            "numbered, from easy to harder, mixing recall, explain-why and (if the topic has them) one "
            "calculation. Use the FACTS and the practice questions in them. Do NOT give the answers; "
            "say they can reply with their answers and you will mark them."
        )
    return (
        f"Write a revision summary of the whole topic \"{t.title}\" ({t.subject}, {t.level}): "
        "one line on what the topic is about, then each part as a short bullet with its key fact or "
        "formula, then the key terms with one-line meanings. Use the FACTS. End with: \"Well done "
        "for finishing this topic!\""
    )


def facts_for(library: PackLibrary, step: Step, budget: int = 5200) -> list[tuple[str, str]]:
    """The pack text for [step]: the part's own entry, then the topic's
    lesson (which has the worked examples and practice questions)."""
    t = step.topic
    chosen: list[Entry] = []
    if step.kind == "part":
        chosen += t.entries_for(t.parts[step.part])
        chosen += [e for e in t.lessons if e not in chosen]
    else:
        chosen += t.lessons + [e for e in t.all_entries if e not in t.lessons]
    out, left = [], budget
    for e in chosen:
        if left < 200:
            break
        allowance = min(left, 3000) if len(chosen) > 1 else left
        text = e.text[:allowance]
        if len(e.text) > allowance:
            text = text.rsplit(". ", 1)[0] + "."
        out.append((e.title, text))
        left -= len(text)
    return out


def suggestions(step: Step, library: PackLibrary) -> list[str]:
    """What the learner may want next, as buttons."""
    t = step.topic
    if step.kind == "part":
        part = t.parts[step.part]
        out = []
        if step.part + 1 < len(t.parts):
            out.append(f"Next: {t.parts[step.part + 1]} ({t.title})")
        else:
            out.append(f"Summarise {t.title}")
        out += [
            f"Give me an example of {part}",
            f"Explain {part} more simply",
            f"Quiz me on {part}" if step.part + 1 < len(t.parts) else f"Quiz me on all of {t.title}",
        ]
        return out
    following = library.next_topic(t)
    out = []
    if step.kind == "quiz":
        out.append(f"Summarise {t.title}")
    else:
        out.append(f"Quiz me on all of {t.title}")
    if following:
        out.append(f"Next topic: {following.title}")
    out.append(f"Teach me {t.title} again")
    return out


def answer_suggestions(entry: Entry, library: PackLibrary) -> list[str]:
    """After an ordinary answer grounded in [entry]: go deeper or learn the
    whole topic."""
    topic = library.topic_of(entry)
    name = (entry.subtopic or entry.title).split(" (")[0]
    out = [f"Explain {name} in detail", f"Give me an example of {name}", f"Explain {name} more simply"]
    if topic is not None:
        out.append(f"Teach me {topic.title}")
    return out
