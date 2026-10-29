"""School isolation, request signing, enrollment and recovery — the spec's
acceptance criteria for the cloud, against two real provisioned schools."""

from __future__ import annotations

import hashlib
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select

from otic_cloud.models import SchoolAudit, SubmissionRecord
from otic_cloud.store import IsolationError

from .conftest import DeviceClient, provision


def submission(device: DeviceClient, uuid: str, learner_uuid: str, answer="3/4"):
    return {
        "id": f"submission:{uuid}",
        "kind": "submission",
        "payload": {
            "uuid": uuid,
            "assignment": "a1",
            "subject": "maths",
            "answer": answer,
            "created_at": "2026-10-13T08:00:00Z",
            "member": f"{device.key[:16]}/1",
            "learner_uuid": learner_uuid,
        },
    }


def push(device: DeviceClient, *records):
    return device.post("/v1/records", {"records": list(records)})


# ── Provisioning ────────────────────────────────────────────────────────────


def test_each_school_has_its_own_database_and_folder(client, two_schools, settings):
    a, b = two_schools["A"]["id"], two_schools["B"]["id"]
    assert a != b
    store = client.app.state.store
    url_a = str(store._engine(a).url)
    url_b = str(store._engine(b).url)
    assert url_a != url_b
    assert (settings.data_dir / "schools" / a / "school.sqlite").is_file()
    assert (settings.data_dir / "schools" / b / "school.sqlite").is_file()


def test_school_ids_are_random_and_unguessable(client):
    ids = {provision(client, f"S{i}")[0] for i in range(3)}
    assert len(ids) == 3
    assert all(i.startswith("sch_") and len(i) == 36 for i in ids)


def test_a_database_that_is_not_the_schools_own_is_refused(client, two_schools):
    store = client.app.state.store
    a, b = two_schools["A"]["id"], two_schools["B"]["id"]
    # Point A's engine at B's database, as a misconfiguration would.
    store._engines[a] = store._engine(b)
    with pytest.raises(IsolationError):
        with store.school_session(a):
            pass


def test_nothing_is_served_until_provisioning_finished(client):
    reg = client.post(
        "/v1/schools/register",
        json={"name": "C", "district": "Gulu", "contact_name": "H", "contact_phone": "1"},
    ).json()
    assert reg["status"] == "pending"
    with pytest.raises(ValueError):
        client.app.state.store.approve("reg_nope")


# ── Cross-school access ─────────────────────────────────────────────────────


def test_school_a_cannot_read_school_b_records(two_schools):
    a, b = two_schools["A"], two_schools["B"]
    assert push(b["learner"], submission(b["learner"], "sub-b", "learner-b")).json() == {
        "accepted": ["submission:sub-b"]
    }
    # A's Admin asks for B's learner: A's database simply has nothing.
    r = a["admin"].get("/v1/records?kind=submission&learner_uuid=learner-b")
    assert r.status_code == 200 and r.json() == {"records": []}
    # B's Admin sees it.
    r = b["admin"].get("/v1/records?kind=submission&learner_uuid=learner-b")
    assert [x["submission"]["uuid"] for x in r.json()["records"]] == ["sub-b"]


def test_a_school_id_in_the_request_is_never_used(two_schools):
    a, b = two_schools["A"], two_schools["B"]
    push(b["learner"], submission(b["learner"], "sub-b", "learner-b"))
    # Every variant of naming B from A's device reaches A's data only.
    for path in [
        f"/v1/records?kind=submission&learner_uuid=learner-b&school_id={b['id']}",
        f"/v1/records?school_id={b['id']}&kind=submission&learner_uuid=learner-b",
    ]:
        r = a["admin"].get(path)
        assert r.json() == {"records": []}
    r = a["admin"].post(
        "/v1/records",
        {"school_id": b["id"], "records": [submission(a["admin"], "x", "learner-b")]},
    )
    assert r.status_code == 200
    store = a["admin"].client.app.state.store
    with store.school_session(b["id"]) as s:
        assert [x.uuid for x in s.scalars(select(SubmissionRecord))] == ["sub-b"]


def test_an_admin_cannot_revoke_another_schools_device(two_schools):
    a, b = two_schools["A"], two_schools["B"]
    r = a["admin"].post("/v1/devices/revoke", {"device_key": b["teacher"].key})
    assert r.status_code == 404
    assert b["teacher"].get("/v1/backups/host").status_code == 200


def test_files_stay_in_their_school(two_schools):
    a, b = two_schools["A"], two_schools["B"]
    pdf = b"%PDF-1.4 school B notes"
    sha = hashlib.sha256(pdf).hexdigest()
    assert b["teacher"].request("PUT", f"/v1/files/{sha}", raw=pdf).status_code == 200
    assert b["learner"].get(f"/v1/files/{sha}").content == pdf
    assert a["teacher"].get(f"/v1/files/{sha}").status_code == 404
    assert a["admin"].get(f"/v1/files/{sha}").status_code == 404


def test_file_names_can_never_leave_the_school_folder(two_schools):
    t = two_schools["A"]["teacher"]
    for name in ["..%2F..%2Fregistry.sqlite", "../registry.sqlite", "x" * 64, "A" * 64]:
        assert t.get(f"/v1/files/{name}").status_code == 404
    # A body that doesn't hash to its name is refused.
    assert t.request("PUT", f"/v1/files/{'0' * 64}", raw=b"other").status_code == 400


def test_unknown_devices_and_bad_signatures_are_refused(client, two_schools):
    stranger = DeviceClient(client)
    assert stranger.get("/v1/records?kind=submission&learner_uuid=x").status_code == 404
    learner = two_schools["A"]["admin"]
    # Signed by another key while claiming the learner's.
    forged = DeviceClient(client)
    path = "/v1/records?kind=submission&learner_uuid=x"
    headers = forged.headers("GET", path, b"")
    headers["X-Otic-Device"] = learner.key
    assert client.get(path, headers=headers).status_code == 404
    # A body changed after signing.
    body = b'{"records": []}'
    headers = learner.headers("POST", "/v1/records", body)
    r = client.post("/v1/records", content=b'{"records":[{}]}', headers=headers)
    assert r.status_code == 404


def test_a_replayed_request_is_refused(client, two_schools):
    teacher = two_schools["A"]["admin"]
    path = "/v1/records?kind=submission&learner_uuid=x"
    headers = teacher.headers("GET", path, b"")
    assert client.get(path, headers=headers).status_code == 200
    assert client.get(path, headers=headers).status_code == 404


def test_a_wrong_clock_is_allowed_within_a_day_but_not_beyond(two_schools):
    teacher = two_schools["A"]["admin"]
    path = "/v1/records?kind=submission&learner_uuid=x"
    now = datetime.now(timezone.utc)
    late = (now - timedelta(hours=5)).isoformat()
    assert teacher.get(path, time=late).status_code == 200
    stale = (now - timedelta(days=3)).isoformat()
    assert teacher.get(path, time=stale).status_code == 404


def test_plain_http_is_refused_unless_allowed(tmp_path):
    from fastapi.testclient import TestClient

    from otic_cloud.api import create_app
    from otic_cloud.config import Settings

    strict = TestClient(create_app(Settings(data_dir=tmp_path)))
    r = strict.post(
        "/v1/schools/register",
        json={"name": "C", "district": "D", "contact_name": "H", "contact_phone": "1"},
    )
    assert r.status_code == 404
    r = strict.post(
        "/v1/schools/register",
        headers={"X-Forwarded-Proto": "https"},
        json={"name": "C", "district": "D", "contact_name": "H", "contact_phone": "1"},
    )
    assert r.status_code == 200


# ── Enrollment and revocation ───────────────────────────────────────────────


def test_codes_are_single_use_and_role_bound(client, two_schools):
    admin = two_schools["A"]["admin"]
    code = admin.post("/v1/enrollment-codes", {"role": "learner"}).json()["code"]
    assert DeviceClient(client).enroll(code, "teacher").status_code == 404
    assert DeviceClient(client).enroll(code, "learner").status_code == 200
    assert DeviceClient(client).enroll(code, "learner").status_code == 404


def test_only_the_admin_issues_codes_or_revokes(two_schools):
    a = two_schools["A"]
    for device in (a["teacher"], a["learner"]):
        assert device.post("/v1/enrollment-codes", {"role": "teacher"}).status_code == 404
        assert device.post(
            "/v1/devices/revoke", {"device_key": a["learner"].key}
        ).status_code == 404


def test_a_device_enrolled_in_one_school_cannot_join_another(two_schools):
    a, b = two_schools["A"], two_schools["B"]
    code = b["admin"].post("/v1/enrollment-codes", {"role": "teacher"}).json()["code"]
    assert a["teacher"].enroll(code, "teacher").status_code == 404


def test_a_revoked_device_is_refused(two_schools):
    a = two_schools["A"]
    assert a["admin"].post(
        "/v1/devices/revoke", {"device_key": a["learner"].key}
    ).status_code == 200
    r = push(a["learner"], submission(a["learner"], "s1", "l1"))
    assert r.status_code == 404


def test_a_teacher_device_cannot_read_learners_records(two_schools):
    a = two_schools["A"]
    push(a["learner"], submission(a["learner"], "s1", "amina"))
    r = a["teacher"].get("/v1/records?kind=submission&learner_uuid=amina")
    assert r.status_code == 404


def test_too_many_wrong_codes_lock_the_address(tmp_path):
    from fastapi.testclient import TestClient

    from otic_cloud.api import create_app
    from otic_cloud.config import Settings

    client = TestClient(
        create_app(Settings(data_dir=tmp_path, allow_http=True, enroll_failures_per_hour=20))
    )
    device = DeviceClient(client)
    for _ in range(20):
        assert device.enroll("WRON-GCOD-E000", "learner").status_code == 404
    assert device.enroll("WRON-GCOD-E000", "learner").status_code == 429


# ── Records ─────────────────────────────────────────────────────────────────


def test_repeats_never_double_and_submissions_are_never_edited(client, two_schools):
    learner = two_schools["A"]["learner"]
    first = submission(learner, "s1", "l1", answer="3/4")
    assert push(learner, first).json()["accepted"] == ["submission:s1"]
    edited = submission(learner, "s1", "l1", answer="changed")
    assert push(learner, edited).json()["accepted"] == ["submission:s1"]
    admin = two_schools["A"]["admin"]
    rows = admin.get("/v1/records?kind=submission&learner_uuid=l1").json()["records"]
    assert len(rows) == 1 and rows[0]["submission"]["answer"] == "3/4"


def test_a_learner_device_sends_only_its_own_learners_work(two_schools):
    a = two_schools["A"]
    other = submission(a["teacher"], "s2", "l2")  # member names another device
    assert push(a["learner"], other).json()["accepted"] == []


def test_grades_only_from_teachers_and_the_highest_version_wins(two_schools):
    a = two_schools["A"]
    push(a["learner"], submission(a["learner"], "s1", "l1"))

    def grade(device, version, value):
        return push(
            device,
            {
                "id": f"grade:s1:{version}",
                "kind": "grade",
                "payload": {"uuid": "s1", "version": version, "grade": value},
            },
        ).json()["accepted"]

    assert grade(a["learner"], 1, 10) == []
    assert grade(a["teacher"], 2, 7) == ["grade:s1:2"]
    assert grade(a["teacher"], 1, 3) == ["grade:s1:1"]
    rows = a["admin"].get("/v1/records?kind=submission&learner_uuid=l1").json()
    assert rows["records"][0]["grade"]["grade"] == 7


def test_assignments_are_publisher_authoritative(client, two_schools):
    a = two_schools["A"]
    record = {
        "id": "assignment:x1",
        "kind": "assignment",
        "payload": {"id": "x1", "title": "Cells", "max": 10},
    }
    assert push(a["teacher"], record).json()["accepted"] == ["assignment:x1"]
    assert push(a["admin"], record).json()["accepted"] == []
    assert push(a["learner"], record).json()["accepted"] == []


# ── Recovery ────────────────────────────────────────────────────────────────


def test_a_replacement_device_recovers_only_the_named_learner(client, two_schools):
    a = two_schools["A"]
    push(a["learner"], submission(a["learner"], "s1", "amina"))
    push(a["learner"], submission(a["learner"], "s2", "brian"))
    # A plain learner device can't read anyone's records.
    assert a["learner"].get(
        "/v1/records?kind=submission&learner_uuid=amina"
    ).status_code == 404
    code = a["admin"].post(
        "/v1/enrollment-codes", {"role": "learner", "learner_uuids": ["amina"]}
    ).json()["code"]
    new_phone = DeviceClient(client)
    assert new_phone.enroll(code, "learner").status_code == 200
    rows = new_phone.get("/v1/records?kind=submission&learner_uuid=amina").json()
    assert [r["submission"]["uuid"] for r in rows["records"]] == ["s1"]
    assert new_phone.get(
        "/v1/records?kind=submission&learner_uuid=brian"
    ).status_code == 404


# ── Audit ───────────────────────────────────────────────────────────────────


def test_refusals_are_audited_in_the_schools_own_log_without_secrets(client, two_schools):
    a = two_schools["A"]
    a["admin"].post("/v1/devices/revoke", {"device_key": a["learner"].key})
    push(a["learner"], submission(a["learner"], "s9", "l9", answer="secret answer"))
    store = client.app.state.store
    with store.school_session(a["id"]) as s:
        rows = s.scalars(select(SchoolAudit)).all()
        actions = [r.action for r in rows]
        text = " ".join(f"{r.action} {r.detail}" for r in rows)
    assert "device.revoked" in actions and "refused.revoked" in actions
    assert "secret answer" not in text
    with store.school_session(two_schools["B"]["id"]) as s:
        assert "refused.revoked" not in [r.action for r in s.scalars(select(SchoolAudit))]


# ── Teacher host backups ────────────────────────────────────────────────────

SEALED = {
    "format": 1,
    "school_id": "x",
    "root_public_key": "k",
    "generation": 1,
    "created_at": "2026-10-13T08:00:00Z",
    "kdf": {"alg": "pbkdf2-hmac-sha256", "rounds": 600000, "salt": "s"},
    "n": "bm9uY2U",
    "c": "Y2lwaGVy",
    "m": "dGFn",
}


def test_host_backups_are_sealed_only_and_stay_in_their_school(two_schools):
    a, b = two_schools["A"], two_schools["B"]
    assert a["teacher"].request(
        "PUT", "/v1/backups/host", {"ledger": SEALED}
    ).status_code == 200
    # Anything readable beyond the header is refused.
    leaky = {**SEALED, "classes": [{"key": "secret"}]}
    assert a["teacher"].request(
        "PUT", "/v1/backups/host", {"ledger": leaky}
    ).status_code == 400
    # Learners can't store or read them.
    assert a["learner"].get("/v1/backups/host").status_code == 404
    listed = a["admin"].get("/v1/backups/host").json()["backups"]
    assert len(listed) == 1
    got = a["admin"].get(f"/v1/backups/host/{listed[0]['id']}").json()
    assert got["ledger"] == SEALED
    # School B sees none of A's, even by id.
    assert b["teacher"].get("/v1/backups/host").json() == {"backups": []}
    assert b["teacher"].get(f"/v1/backups/host/{listed[0]['id']}").status_code == 404


def test_only_the_latest_three_backups_per_device_are_kept(two_schools):
    t = two_schools["A"]["teacher"]
    for _ in range(5):
        t.request("PUT", "/v1/backups/host", {"ledger": SEALED})
    assert len(t.get("/v1/backups/host").json()["backups"]) == 3
