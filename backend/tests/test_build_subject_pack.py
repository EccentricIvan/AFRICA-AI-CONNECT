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


def test_clip_names_match_words_not_substrings_or_unrelated_article_media():
    assert not names_all("Pressure washing.webm", {"press"})
    assert not names_all("Office of Nuclear Energy gigawatts.ogv", {"power"})
    assert not names_all("MRI demonstration.webm", {"energy"})
    assert names_all("Magnetic fields demonstration.webm", {"magnetic", "field"})
    assert not _clips_of([_video("2019 lever-soleil.webm"),
                          _video("Salvia-pratensis-staminal-lever.webm")],
                         require={"lever"})


def test_curated_subject_rebuilds_do_not_add_unapproved_search_results():
    from otic_cloud.build_subject_pack import selected_clips
    candidates = [{'name': 'Brownian Motion.ogv'}, {'name': 'Research demo.webm'}]
    source = {'clip_allowlist': {'Matter': ['Brownian Motion.ogv']}}
    assert selected_clips(source, 'Matter', candidates) == [candidates[0]]
    assert selected_clips(source, 'Other topic', candidates) == []
    assert selected_clips({}, 'Matter', candidates) == candidates


def test_audio_files_are_not_video_clips():
    page = _video('Light year.ogg')
    page['videoinfo'][0]['mime'] = 'audio/ogg'
    assert _clips_of([page], require={'light', 'year'}) == []


def test_curated_build_uses_exact_clips_and_scopes_image_exclusions(tmp_path, monkeypatch):
    import json
    from otic_cloud import build_subject_pack as b

    sources = tmp_path / 'pack_sources'
    sources.mkdir()
    source_url = 'https://commons.wikimedia.org/wiki/File:diagram.png'
    (sources / 'physics.json').write_text(json.dumps({
        'title': 'Physics',
        'topics': {'First': [['Shared', 'Shared']], 'Second': [['Shared', 'Shared']]},
        'clip_allowlist': {'First': ['Brownian Motion.ogv']},
        'excluded_media_sources': {'physics.s1.first.shared|' + source_url: 'Wrong context'},
    }), encoding='utf-8')
    assets = tmp_path / 'assets'
    (assets / 'curriculum').mkdir(parents=True)
    (assets / 'curriculum/physics.json').write_text(json.dumps({
        'name': 'Physics', 'units': [{'title': 'S1', 'lessons': [
            {'title': 'First', 'content': 'First lesson'},
            {'title': 'Second', 'content': 'Second lesson'},
        ]}],
    }), encoding='utf-8')
    calls = []

    class FakeFetcher:
        def __init__(self, cache):
            pass

        def json(self, url, params):
            calls.append(params)
            assert params['titles'] == 'File:Brownian Motion.ogv'
            return {'query': {'pages': [_video('Brownian Motion.ogv')]}}

        def download(self, url, dest, max_bytes):
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(b'fixture')
            return True

    monkeypatch.setattr(b, '__file__', str(tmp_path / 'build_subject_pack.py'))
    monkeypatch.setattr(b, 'Fetcher', FakeFetcher)
    monkeypatch.setattr(b, 'reference_text', lambda *args: ('Reference text', 'Shared', 1))
    monkeypatch.setattr(b, 'article_pictures', lambda *args: [{
        'kind': 'image', 'name': 'diagram.png', 'url': 'https://x/diagram.png',
        'caption': 'Diagram', 'credit': 'A, CC BY 4.0', 'licence': 'CC BY 4.0', 'source': source_url,
    }])
    pack = b.build('physics', assets, tmp_path / 'output')
    assert len(calls) == 1
    first = next(e for e in pack['entries'] if e['id'] == 'physics.s1.first.shared')
    second = next(e for e in pack['entries'] if e['id'] == 'physics.s1.second.shared')
    assert first['media'] == []
    assert len(second['media']) == 1
    assert sum(m['kind'] == 'clip' for m in pack['media']) == 1
