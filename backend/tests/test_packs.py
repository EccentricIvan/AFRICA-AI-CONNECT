from __future__ import annotations

import json

from otic_cloud.packs import FORMAT, PackLibrary, words


def _pack(tmp_path, entries, status="draft", name="pack.json"):
    (tmp_path / name).write_text(
        json.dumps({"format": FORMAT, "id": "test", "status": status, "entries": entries}),
        encoding="utf-8",
    )


LESSONS = [
    {
        "id": "geo.africa",
        "title": "Africa: Location, Relief and Drainage",
        "text": "Africa straddles the equator; about two-thirds of it lies in the "
        "Northern Hemisphere. It is bordered by the Atlantic Ocean to the west.",
        "keyTerms": {"plateau": "A raised flat area"},
    },
    {
        "id": "bio.photosynthesis",
        "title": "Photosynthesis",
        "text": "Green plants make glucose from carbon dioxide and water using light.",
    },
    {
        "id": "eco.trade",
        "title": "Trade in East Africa",
        "text": "Countries in East Africa trade crops. What causes trade? Different resources.",
    },
]


def test_word_roots_match_across_forms():
    assert words("located") == words("location") == words("locate")
    assert words("volcanoes") == words("volcano")


def test_the_entry_a_question_is_about_comes_first(tmp_path):
    _pack(tmp_path, LESSONS)
    lib = PackLibrary.load(tmp_path)
    found = lib.search("Where is Africa located on the globe?")
    assert found[0].entry.id == "geo.africa"
    assert "two-thirds" in found[0].text


def test_a_question_no_entry_covers_finds_nothing(tmp_path):
    _pack(tmp_path, LESSONS)
    assert PackLibrary.load(tmp_path).search("What causes inflation?") == []


def test_a_follow_up_uses_the_earlier_question(tmp_path):
    _pack(tmp_path, LESSONS)
    lib = PackLibrary.load(tmp_path)
    found = lib.search("Which ocean is to its west?", context="Where is Africa?")
    assert found[0].entry.id == "geo.africa"


def test_long_entries_are_cut_to_the_matching_sentences(tmp_path):
    filler = " ".join(f"Sentence {i} is about something else." for i in range(200))
    _pack(tmp_path, [{"id": "x", "title": "Rivers", "text": f"{filler} The Nile flows north. {filler}"}])
    found = PackLibrary.load(tmp_path).search("Does the Nile flow north?", budget=400)
    assert "The Nile flows north." in found[0].text
    assert len(found[0].text) <= 400


def test_files_that_are_not_packs_are_skipped(tmp_path):
    (tmp_path / "notes.json").write_text('{"hello": 1}', encoding="utf-8")
    (tmp_path / "broken.json").write_text("{", encoding="utf-8")
    _pack(tmp_path, LESSONS, status="reviewed")
    lib = PackLibrary.load(tmp_path)
    assert len(lib.entries) == 3
    assert all(e.reviewed for e in lib.entries)


def test_no_folder_means_no_entries():
    assert PackLibrary.load(None).search("anything") == []


def subject_pack(tmp_path):
    """A small subject pack in its own folder, with a picture and a clip."""
    folder = tmp_path / "physics"
    (folder / "media" / "s1" / "heat").mkdir(parents=True)
    (folder / "media" / "s1" / "heat" / "convection-1.png").write_bytes(b"png")
    (folder / "media" / "s1" / "heat" / "clip-1.webm").write_bytes(b"webm")
    (folder / "media" / "s1" / "heat" / "clip-1.jpg").write_bytes(b"jpg")
    (tmp_path / "secret.txt").write_text("not media", encoding="utf-8")
    (folder / "pack.json").write_text(
        json.dumps({
            "format": FORMAT,
            "id": "physics",
            "entries": [
                {"id": "t.lesson", "topic": "t", "title": "Heat Transfer",
                 "text": "Heat moves by conduction, convection and radiation.", "media": ["t.clip1"]},
                {"id": "t.conv", "topic": "t", "title": "Convection (Heat Transfer)",
                 "text": "Convection carries heat by moving fluid.", "media": ["t.conv.m1"]},
            ],
            "media": [
                {"id": "t.conv.m1", "kind": "image", "file": "media/s1/heat/convection-1.png",
                 "caption": "Convection currents", "credit": "A. Author, CC BY 4.0"},
                {"id": "t.clip1", "kind": "clip", "file": "media/s1/heat/clip-1.webm",
                 "poster": "media/s1/heat/clip-1.jpg", "seconds": 75,
                 "caption": "Convection in water", "credit": "B. Author, CC0"},
            ],
        }),
        encoding="utf-8",
    )
    return PackLibrary.load(tmp_path)


def test_a_subject_folder_pack_loads_with_its_media(tmp_path):
    lib = subject_pack(tmp_path)
    found = lib.search("What is convection?")
    assert found[0].entry.id == "t.conv"
    # The entry's own picture first, then the rest of its topic (the clip).
    assert [m.id for m in lib.media_for(found)] == ["t.conv.m1", "t.clip1"]
    assert [m.id for m in lib.media_for(found, clips=True)] == ["t.clip1"]
    assert [m.id for m in lib.media_for(found, clips=False)] == ["t.conv.m1"]


def test_only_files_inside_a_packs_media_folder_are_served(tmp_path):
    lib = subject_pack(tmp_path)
    assert lib.media_file("physics", "media/s1/heat/convection-1.png").read_bytes() == b"png"
    assert lib.media_file("physics", "pack.json") is None
    assert lib.media_file("physics", "media/../../secret.txt") is None
    assert lib.media_file("physics", "media/s1/heat/missing.png") is None
    assert lib.media_file("chemistry", "media/x.png") is None


def test_generic_followups_use_the_existing_topic(tmp_path):
    _pack(tmp_path, LESSONS)
    lib=PackLibrary.load(tmp_path)
    for question in ['Tell me more','Give me an example','Expound more']:
        found=lib.search(question,context='Where is Africa located?')
        assert found and found[0].entry.id=='geo.africa'
    assert lib.search('Tell me more')==[]


def test_teaching_style_words_do_not_distort_subject_retrieval(tmp_path):
    _pack(tmp_path, LESSONS)
    lib=PackLibrary.load(tmp_path)
    assert lib.search('Explain briefly where Africa is located')[0].entry.id=='geo.africa'
