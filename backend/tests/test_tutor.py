from __future__ import annotations

import json
from types import SimpleNamespace

import httpx
import pytest
from fastapi.testclient import TestClient

from otic_cloud.packs import FORMAT, Entry, PackLibrary
from otic_cloud.tutor import HUB_RULES, MODEL, SYSTEM_PROMPT, create_tutor_app
from tests.test_packs import subject_pack


class FakeClaude:
    """Stands in for anthropic.Anthropic: records each request, answers with
    [reply] (or refuses)."""

    def __init__(self, reply: str = "Photosynthesis makes glucose.", stop_reason: str = "end_turn"):
        self.calls: list[dict] = []
        self.reply = reply
        self.stop_reason = stop_reason
        self.beta = SimpleNamespace(messages=SimpleNamespace(create=self._create))

    def _create(self, **kwargs):
        self.calls.append(kwargs)
        return SimpleNamespace(
            stop_reason=self.stop_reason,
            model=kwargs["model"],
            content=[SimpleNamespace(type="text", text=self.reply)],
        )


@pytest.fixture
def claude():
    return FakeClaude()


@pytest.fixture
def client(claude):
    return TestClient(create_tutor_app(client_factory=lambda: claude, access_token=""))


def test_answers_with_the_guardrailed_prompt(client, claude):
    r = client.post("/v1/tutor/answer", json={"message": "What is photosynthesis?"})
    assert r.status_code == 200
    assert r.json() == {"text": "Photosynthesis makes glucose.", "model": MODEL, "suggestions": []}
    call = claude.calls[0]
    assert call["model"] == MODEL
    assert call["system"] == SYSTEM_PROMPT
    assert call["fallbacks"] == "default"
    assert call["messages"] == [{"role": "user", "content": "What is photosynthesis?"}]


def test_lesson_material_goes_in_front_of_the_question(client, claude):
    client.post(
        "/v1/tutor/answer",
        json={"message": "Why does it need light?", "lesson": "Topic: Photosynthesis"},
    )
    content = claude.calls[0]["messages"][-1]["content"]
    assert content.startswith("LESSON:\nTopic: Photosynthesis")
    assert content.endswith("QUESTION:\nWhy does it need light?")


def test_history_is_trimmed_to_alternate_and_start_with_the_learner(client, claude):
    client.post(
        "/v1/tutor/answer",
        json={
            "message": "And in animals?",
            "history": [
                {"role": "assistant", "content": "Hello!"},
                {"role": "user", "content": "What is respiration?"},
                {"role": "assistant", "content": "Releasing energy from food."},
                {"role": "assistant", "content": "Any questions?"},
            ],
        },
    )
    roles = [m["role"] for m in claude.calls[0]["messages"]]
    assert roles == ["user", "assistant", "user"]
    assert claude.calls[0]["messages"][1]["content"].endswith("Any questions?")


def test_a_refusal_becomes_a_redirect_to_school_work():
    refusing = FakeClaude(reply="", stop_reason="refusal")
    c = TestClient(create_tutor_app(client_factory=lambda: refusing, access_token=""))
    r = c.post("/v1/tutor/answer", json={"message": "something harmful"})
    assert r.status_code == 200
    assert "school subjects" in r.json()["text"]


def test_without_a_key_it_says_so_and_the_app_answers_offline(monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    c = TestClient(create_tutor_app(access_token=""))
    assert c.get("/v1/tutor/health").json()["configured"] is False
    r = c.post("/v1/tutor/answer", json={"message": "What is algebra?"})
    assert r.status_code == 503
    assert r.json() == {"error": "not_configured"}


def test_the_access_token_is_checked_when_set(claude):
    c = TestClient(create_tutor_app(client_factory=lambda: claude, access_token="s3cret"))
    assert c.post("/v1/tutor/answer", json={"message": "hi"}).status_code == 401
    ok = c.post(
        "/v1/tutor/answer",
        json={"message": "hi"},
        headers={"X-Otic-Tutor-Token": "s3cret"},
    )
    assert ok.status_code == 200


def test_oversized_requests_are_refused(client, claude):
    r = client.post("/v1/tutor/answer", json={"message": "x" * 2001})
    assert r.status_code == 422
    assert claude.calls == []


class FakeHub:
    """Stands in for the hub's llama-server: records each request."""

    def __init__(self, reply="Africa lies across the equator.", fail=False):
        self.calls: list[tuple[str, dict]] = []
        self.reply = reply
        self.fail = fail

    def __call__(self, url, body, timeout):
        self.calls.append((url, body))
        if self.fail:
            raise httpx.ConnectError("refused")
        return {"model": "qwen3-4b", "choices": [{"message": {"content": self.reply}}]}


@pytest.fixture
def library():
    return PackLibrary(
        [
            Entry(
                id="geo.africa",
                title="Africa: Location, Relief and Drainage",
                text="About two-thirds of Africa lies in the Northern Hemisphere.",
            )
        ]
    )


def _hub_client(hub, library):
    return TestClient(
        create_tutor_app(access_token="", hub_url="http://hub:8090/", packs=library, hub_post=hub)
    )


def test_the_hub_answers_from_the_matching_pack_text(library):
    hub = FakeHub()
    c = _hub_client(hub, library)
    assert c.get("/v1/tutor/health").json()["packEntries"] == 1
    r = c.post("/v1/tutor/answer", json={"message": "Where is Africa located?"})
    assert r.status_code == 200
    assert r.json()["text"].startswith("Africa lies across the equator.")
    assert "Source: school content pack — Africa: Location" in r.json()["text"]
    url, body = hub.calls[0]
    assert url == "http://hub:8090/v1/chat/completions"
    assert body["messages"][0] == {"role": "system", "content": SYSTEM_PROMPT + HUB_RULES}
    question = body["messages"][-1]["content"]
    assert question.startswith("FACTS:\n[Africa: Location, Relief and Drainage]\nAbout two-thirds")
    assert question.endswith("QUESTION:\nWhere is Africa located?")
    assert body["chat_template_kwargs"] == {"enable_thinking": False}


def test_the_hub_keeps_the_chat_and_drops_thinking(library):
    hub = FakeHub(reply="<think>hmm</think>It is hot near the equator.")
    c = _hub_client(hub, library)
    r = c.post(
        "/v1/tutor/answer",
        json={
            "message": "Why is it hot there?",
            "history": [
                {"role": "user", "content": "Where is Africa?"},
                {"role": "assistant", "content": "Across the equator."},
            ],
        },
    )
    assert r.json()["text"].startswith("It is hot near the equator.")
    roles = [m["role"] for m in hub.calls[0][1]["messages"]]
    assert roles == ["system", "user", "assistant", "user"]
    # The follow-up found the topic through the earlier question.
    assert "FACTS:" in hub.calls[0][1]["messages"][-1]["content"]


def test_content_miss_allows_internet_fallback_without_model_guessing(library):
    hub = FakeHub()
    c = _hub_client(hub, library)
    r = c.post("/v1/tutor/answer", json={"message": "What is photosynthesis?"})
    assert r.status_code == 204
    assert hub.calls == []
    assert c.get("/v1/tutor/health").json()["configured"] is True


def test_matching_app_lesson_can_ground_an_answer_without_hub_pack(library):
    hub = FakeHub(reply="Photosynthesis makes food.")
    c = _hub_client(hub, library)
    r = c.post("/v1/tutor/answer", json={
        "message": "What is photosynthesis?",
        "lesson": "Photosynthesis uses light to make glucose.",
    })
    assert r.status_code == 200
    assert r.json()["text"] == "Photosynthesis makes food."


def test_a_hub_that_is_down_lets_the_app_answer_offline(library):
    c = _hub_client(FakeHub(fail=True), library)
    r = c.post("/v1/tutor/answer", json={"message": "Where is Africa?"})
    assert r.status_code == 502
    assert r.json() == {"error": "offline"}


def test_hub_answers_show_the_packs_pictures_and_clips(tmp_path):
    hub = FakeHub(reply="Convection moves heat by moving fluid.")
    c = _hub_client(hub, subject_pack(tmp_path))
    text = c.post("/v1/tutor/answer", json={"message": "What is convection?"}).json()["text"]
    base = "http://testserver/v1/hub/media/physics/media/s1/heat/"
    assert f"![Convection currents]({base}convection-1.png)" in text
    assert f"[![▶ Convection in water]({base}clip-1.jpg)]({base}clip-1.webm)" in text
    assert f"[▶ Watch: Convection in water]({base}clip-1.webm) (1:15)" in text
    assert text.index("clip-1.webm") < text.index("Source: school content pack")
    assert c.get("/v1/hub/media/physics/media/s1/heat/convection-1.png").content == b"png"
    assert c.get("/v1/hub/media/physics/pack.json").status_code == 404


def test_the_app_can_ask_the_hub_for_pictures_or_clips(tmp_path):
    c = _hub_client(FakeHub(), subject_pack(tmp_path))
    pictures = c.get("/v1/hub/pictures", params={"q": "convection"}).json()["items"]
    assert [(p["kind"], p["caption"]) for p in pictures] == [("image", "Convection currents")]
    clips = c.get("/v1/hub/pictures", params={"q": "convection", "clips": "true"}).json()["items"]
    assert clips[0]["url"].endswith("/clip-1.webm")
    assert clips[0]["poster"].endswith("/clip-1.jpg")
    assert clips[0]["seconds"] == 75
    assert c.get("/v1/hub/pictures", params={"q": "inflation"}).json() == {"items": []}


def test_the_hub_teaches_a_topic_part_by_part_with_suggestions(tmp_path):
    folder = tmp_path / "physics"
    (folder / "media").mkdir(parents=True)
    (folder / "media" / "conv.png").write_bytes(b"png")
    (folder / "pack.json").write_text(json.dumps({
        "format": FORMAT, "id": "physics", "subject": "Physics",
        "topics": [{"id": "heat", "level": "S1", "title": "Heat Transfer",
                    "subtopics": ["Conduction", "Convection"], "entries": ["heat.lesson", "heat.conv"]}],
        "entries": [
            {"id": "heat.lesson", "topic": "heat", "kind": "lesson", "title": "Heat Transfer",
             "text": "Heat moves by conduction and convection."},
            {"id": "heat.conv", "topic": "heat", "kind": "reference", "subtopic": "Convection",
             "title": "Convection (Heat Transfer)", "text": "Convection carries heat.", "media": ["m1"]},
        ],
        "media": [{"id": "m1", "kind": "image", "file": "media/conv.png", "caption": "Currents", "credit": "A"}],
    }), encoding="utf-8")
    lib = PackLibrary.load(tmp_path)
    hub = FakeHub(reply="Convection is how heat moves through liquids and gases.")
    c = _hub_client(hub, lib)
    r = c.post("/v1/tutor/answer", json={"message": "Teach me convection"}).json()
    assert "We'll go through it in 2 parts" in r["text"]
    assert "**Heat Transfer — Part 2 of 2: Convection**\n\nConvection is how heat moves" in r["text"]
    assert "![Currents](http://testserver/v1/hub/media/physics/media/conv.png)" in r["text"]
    assert r["suggestions"][0] == "Summarise Heat Transfer"
    task = hub.calls[0][1]["messages"][-1]["content"]
    assert task.startswith("FACTS:\n[Convection (Heat Transfer)]\nConvection carries heat.")
    assert 'teach ONLY part 2 of 2: "Convection"' in task
    assert task.endswith("LEARNER SAID:\nTeach me convection")


def test_ordinary_hub_answers_suggest_going_deeper(library):
    r = _hub_client(FakeHub(), library).post("/v1/tutor/answer", json={"message": "Where is Africa?"}).json()
    assert r["suggestions"] == [
        "Give me an example of Africa: Location, Relief and Drainage",
        "Explain Africa: Location, Relief and Drainage more simply",
    ]


def test_the_hub_checks_the_access_token(library):
    c = TestClient(
        create_tutor_app(access_token="s3cret", hub_url="http://hub", packs=library, hub_post=FakeHub())
    )
    assert c.post("/v1/tutor/answer", json={"message": "hi"}).status_code == 401
