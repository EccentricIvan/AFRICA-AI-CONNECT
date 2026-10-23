from __future__ import annotations

from otic_cloud.build_subject_pack import _clips_of, key_words, lesson_text, names_all, readme


def test_key_words_are_what_a_topic_is_about():
    assert key_words("Brownian motion") == {"brownian", "motion"}
    assert key_words("Micrometer (device)", "Micrometer screw gauge") == {"micrometer", "screw", "gauge"}
    assert key_words("What physics is") == set()
    assert names_all("Brownian_Motion.ogv".replace("_", " "), {"brownian", "motion"})
    assert not names_all("Micrometer-scaled droplets.webm", {"micrometer", "screw", "gauge"})
    assert not names_all("anything.webm", set())


def _video(name, seconds=60, licence="CC BY-SA 4.0"):
    return {
        "title": f"File:{name}",
        "videoinfo": [{
            "duration": seconds,
            "url": f"https://upload.wikimedia.org/{name}",
            "size": 1000,
            "derivatives": [{"type": "video/webm; codecs=vp9", "height": 360, "src": f"https://x/{name}.360p.webm"}],
            "extmetadata": {"LicenseShortName": {"value": licence}},
        }],
    }


def test_clips_must_be_free_teaching_length_and_on_topic():
    pages = [
        _video("Brownian Motion.ogv"),
        _video("Brownian motion loop.webm", seconds=6),  # too short to teach
        _video("Brownian motion lecture.webm", seconds=3600),  # too long
        _video("Brownian motion ncomms15634.webm"),  # research data
        _video("Brownian motion demo.webm", licence="CC BY-NC 4.0"),  # not free
        _video("Some politician speaking.webm"),  # off topic
    ]
    clips = _clips_of(pages, require={"brownian", "motion"})
    assert [c["name"] for c in clips] == ["Brownian Motion.ogv"]
    assert clips[0]["url"].endswith(".360p.webm")


def test_a_lesson_keeps_its_examples_and_practice_answers():
    text = lesson_text({
        "content": "Density is mass per unit volume.",
        "examples": ["Find the density of 20 g in 10 cm3.\nAnswer: 2 g/cm3"],
        "quiz": [{"question": "Unit of density?", "options": ["kg", "kg/m3"], "correct": 1, "explanation": "Mass over volume."}],
    })
    assert "Worked examples:\nFind the density" in text
    assert "Q: Unit of density?\nAnswer: kg/m3. Mass over volume." in text


def test_the_readme_lists_every_class_and_topic():
    pack = {
        "title": "Physics (S1–S4)", "version": "2026-10-23", "status": "draft",
        "topics": [{"level": "S1", "title": "Heat Transfer", "subtopics": ["Convection"], "media": ["a", "b"]}],
        "media": [{"id": "a", "kind": "image"}, {"id": "b", "kind": "clip"}],
    }
    text = readme(pack)
    assert "S1\n--\nHeat Transfer  (1 pictures, 1 clips)\n    - Convection" in text
    assert "DRAFT" in text
