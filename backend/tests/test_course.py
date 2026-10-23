from __future__ import annotations

import json

import pytest

from otic_cloud import course
from otic_cloud.packs import FORMAT, PackLibrary


def _entry(id, topic, title, text, kind="reference", subtopic="", media=()):
    return {"id": id, "topic": topic, "kind": kind, "title": title, "subtopic": subtopic,
            "text": text, "media": list(media)}


@pytest.fixture
def library(tmp_path):
    folder = tmp_path / "physics"
    (folder / "media").mkdir(parents=True)
    (folder / "media" / "conv.png").write_bytes(b"png")
    pack = {
        "format": FORMAT, "id": "physics", "subject": "Physics",
        "topics": [
            {"id": "heat", "level": "S1", "title": "Heat Transfer",
             "subtopics": ["Conduction", "Convection", "Radiation"],
             "entries": ["heat.lesson", "heat.cond", "heat.conv", "heat.rad"]},
            {"id": "exp", "level": "S1", "title": "Expansion of Solids, Liquids and Gases",
             "subtopics": ["Thermal expansion"], "entries": ["exp.lesson"]},
        ],
        "entries": [
            _entry("heat.lesson", "heat", "Heat Transfer", "Heat moves by conduction, convection and radiation.", kind="lesson"),
            _entry("heat.cond", "heat", "Conduction (Heat Transfer)", "Conduction passes heat through solids.", subtopic="Conduction"),
            _entry("heat.conv", "heat", "Convection (Heat Transfer)", "Convection carries heat in moving fluids.",
                   subtopic="Convection", media=["heat.conv.m1"]),
            _entry("heat.rad", "heat", "Radiation (Heat Transfer)", "Radiation carries heat as infrared waves.", subtopic="Radiation"),
            _entry("exp.lesson", "exp", "Expansion of Solids, Liquids and Gases", "Most things expand when heated.", kind="lesson"),
        ],
        "media": [{"id": "heat.conv.m1", "kind": "image", "file": "media/conv.png",
                   "caption": "Convection currents", "credit": "A, CC BY 4.0"}],
    }
    (folder / "pack.json").write_text(json.dumps(pack), encoding="utf-8")
    return PackLibrary.load(tmp_path)


def test_teach_me_a_topic_starts_at_part_one_with_the_plan(library):
    step = course.plan_step(library, "Teach me heat transfer", [])
    assert (step.kind, step.topic.title, step.part, step.show_plan) == ("part", "Heat Transfer", 0, True)
    plan = course.plan_text(step.topic, step.part)
    assert "1. Conduction\n2. Convection\n3. Radiation" in plan


def test_teach_me_a_part_starts_there(library):
    step = course.plan_step(library, "can you teach me about convection?", [])
    assert (step.topic.title, step.part) == ("Heat Transfer", 1)
    assert "2. Convection ← we start here" in course.plan_text(step.topic, step.part)


def test_the_next_button_and_typing_next_both_move_on(library):
    step = course.plan_step(library, "Next: Radiation (Heat Transfer)", [])
    assert step.part == 2
    earlier = ["...", "**Heat Transfer — Part 1 of 3: Conduction**\n\nConduction is..."]
    assert course.plan_step(library, "next", earlier).part == 1
    assert course.plan_step(library, "continue please", earlier).part == 1


def test_after_the_last_part_comes_the_summary(library):
    earlier = ["**Heat Transfer — Part 3 of 3: Radiation**\n\n..."]
    step = course.plan_step(library, "next", earlier)
    assert step.kind == "summary"
    assert course.suggestions(step, library) == [
        "Quiz me on all of Heat Transfer",
        "Next topic: Expansion of Solids, Liquids and Gases",
        "Teach me Heat Transfer again",
    ]


def test_quiz_me_quizzes_the_topic_under_way(library):
    earlier = ["**Heat Transfer — Part 2 of 3: Convection**\n\n..."]
    assert course.plan_step(library, "quiz me", earlier).kind == "quiz"
    assert course.plan_step(library, "Quiz me on all of Heat Transfer", []).topic.title == "Heat Transfer"


def test_ordinary_questions_are_not_course_steps(library):
    assert course.plan_step(library, "What is convection?", []) is None
    assert course.plan_step(library, "next", []) is None
    assert course.plan_step(library, "teach me how to bake bread", []) is None


def test_each_part_suggests_the_next_part_and_ways_to_go_deeper(library):
    step = course.plan_step(library, "teach me heat transfer", [])
    assert course.suggestions(step, library) == [
        "Next: Convection (Heat Transfer)",
        "Give me an example of Conduction",
        "Explain Conduction more simply",
        "Quiz me on Conduction",
    ]
    last = course.plan_step(library, "Next: Radiation (Heat Transfer)", [])
    assert course.suggestions(last, library)[0] == "Summarise Heat Transfer"
    assert course.suggestions(last, library)[-1] == "Quiz me on all of Heat Transfer"


def test_a_parts_facts_put_its_own_text_first(library):
    step = course.plan_step(library, "Next: Convection (Heat Transfer)", [])
    facts = course.facts_for(library, step)
    assert [title for title, _ in facts] == ["Convection (Heat Transfer)", "Heat Transfer"]
