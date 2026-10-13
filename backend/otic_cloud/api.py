"""The school cloud API (docs/CLOUD_API.md).

Every signed request is bound to exactly one school before any record is
read: the device's public key is looked up in the registry, and its
school's own database is opened. Nothing in the URL or body chooses the
school. Every refusal is the same bare 404.
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import re
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, Response
from sqlalchemy import delete, func, select

from .config import Settings
from .models import (
    AssignmentRecord,
    Device,
    EnrollFailure,
    EnrollmentCode,
    FileRecord,
    GradeRecord,
    HostBackup,
    Nonce,
    School,
    SubmissionRecord,
)
from .store import IsolationError, Store, hash_code, now_iso, parse_iso

SHA256 = re.compile(r"^[0-9a-f]{64}$")
KEY = re.compile(r"^[A-Za-z0-9_-]{43}$")
UUID_LIKE = re.compile(r"^[A-Za-z0-9_.:-]{1,64}$")
ROLES = ("admin", "teacher", "learner")
MAX_RECORDS = 50
LEDGER_KEYS = {
    "format", "school_id", "root_public_key", "generation", "created_at",
    "kdf", "n", "c", "m",
}


class Refused(Exception):
    """Anything refused: answered with the same bare 404."""


def _not_found() -> Response:
    return Response(status_code=404)


def unb64(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def signed_bytes(method: str, path: str, time: str, nonce: str, body: bytes) -> bytes:
    return "\n".join(
        [
            "otic-cloud-req-v1",
            method.upper(),
            path,
            time,
            nonce,
            hashlib.sha256(body).hexdigest(),
        ]
    ).encode()


@dataclass
class Caller:
    device: Device
    school_id: str


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings.from_env()
    store = Store(settings)
    app = FastAPI(title="AI Connect Africa school cloud", docs_url=None, redoc_url=None)
    app.state.store = store

    # ── Transport ───────────────────────────────────────────────────────

    def _https_ok(request: Request) -> bool:
        if settings.allow_http:
            return True
        proto = request.headers.get("x-forwarded-proto", request.url.scheme)
        return proto == "https"

    async def _body(request: Request, limit: int) -> bytes:
        declared = request.headers.get("content-length")
        if declared and declared.isdigit() and int(declared) > limit:
            raise OverflowError
        body = await request.body()
        if len(body) > limit:
            raise OverflowError
        return body

    def _path(request: Request) -> str:
        q = request.url.query
        return request.url.path + (f"?{q}" if q else "")

    # ── Who is asking ───────────────────────────────────────────────────

    def _caller(request: Request, body: bytes) -> Caller:
        h = request.headers
        key, sig = h.get("x-otic-device", ""), h.get("x-otic-sig", "")
        time, nonce = h.get("x-otic-time", ""), h.get("x-otic-nonce", "")
        if not KEY.match(key) or not 16 <= len(nonce) <= 64 or not sig:
            raise Refused
        with store.registry() as s:
            device = s.get(Device, key)
            school = s.get(School, device.school_id) if device else None
        if device is None or school is None:
            store.operator_audit("refused.unknown_device", request.url.path)
            raise Refused
        if device.status != "active" or school.status != "active":
            _audit_refusal(school.id, key, "refused.revoked", request)
            raise Refused
        try:
            Ed25519PublicKey.from_public_bytes(unb64(key)).verify(
                unb64(sig),
                signed_bytes(request.method, _path(request), time, nonce, body),
            )
        except (InvalidSignature, ValueError):
            _audit_refusal(school.id, key, "refused.signature", request)
            raise Refused
        sent = parse_iso(time)
        now = datetime.now(timezone.utc)
        if sent is None or abs(now - sent) > timedelta(hours=settings.clock_window_hours):
            _audit_refusal(school.id, key, "refused.clock", request)
            raise Refused
        with store.school_session(school.id) as s:
            cutoff = (now - timedelta(hours=settings.nonce_hours)).isoformat()
            s.execute(delete(Nonce).where(Nonce.at < cutoff))
            if s.get(Nonce, (key, nonce)) is not None:
                replay = True
            else:
                replay = False
                s.add(Nonce(device=key, nonce=nonce, at=now.isoformat()))
        if replay:
            _audit_refusal(school.id, key, "refused.replay", request)
            raise Refused
        return Caller(device=device, school_id=school.id)

    def _audit_refusal(school_id: str, key: str, action: str, request: Request):
        try:
            store.school_audit(school_id, action, key, request.url.path, ok=False)
        except IsolationError:
            pass

    def _require(caller: Caller, *roles: str) -> None:
        if caller.device.role not in roles:
            store.school_audit(
                caller.school_id, "refused.role", caller.device.key, caller.device.role, ok=False
            )
            raise Refused

    async def _signed(request: Request, limit: int | None = None) -> tuple[Caller, bytes]:
        if not _https_ok(request):
            raise Refused
        body = await _body(request, limit or settings.max_body_bytes)
        return _caller(request, body), body

    def _json(body: bytes) -> dict:
        data = json.loads(body or b"{}")
        if not isinstance(data, dict):
            raise ValueError
        return data

    @app.exception_handler(Refused)
    async def _refused(_, __):
        return _not_found()

    @app.exception_handler(IsolationError)
    async def _isolation(_, exc):
        store.operator_audit("isolation.error", str(exc))
        return _not_found()

    @app.exception_handler(OverflowError)
    async def _too_big(_, __):
        return Response(status_code=413)

    @app.exception_handler(ValueError)
    async def _bad(_, __):
        return Response(status_code=400)

    # ── Registration (public) ───────────────────────────────────────────

    @app.post("/v1/schools/register")
    async def register(request: Request):
        if not _https_ok(request):
            raise Refused
        data = _json(await _body(request, 8 * 1024))
        fields = {}
        for name, limit, required in [
            ("name", 200, True),
            ("district", 100, True),
            ("contact_name", 120, True),
            ("contact_phone", 40, True),
            ("emis_number", 40, False),
        ]:
            v = data.get(name)
            if v is None and not required:
                continue
            if not isinstance(v, str) or not v.strip() or len(v) > limit:
                raise ValueError
            fields[name] = v.strip()
        key = f"register|{_address(request)}"
        if _too_many_failures(key):
            return Response(status_code=429)
        rid = store.register(**fields)
        # Counted, so registrations can't be flooded.
        _record_failure(key)
        return {"registration_id": rid, "status": "pending"}

    # ── Enrollment ──────────────────────────────────────────────────────

    def _address(request: Request) -> str:
        return (request.client.host if request.client else "unknown")[:64]

    def _too_many_failures(address: str) -> bool:
        since = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
        with store.registry() as s:
            n = s.scalar(
                select(func.count())
                .select_from(EnrollFailure)
                .where(EnrollFailure.address == address, EnrollFailure.at >= since)
            )
        return (n or 0) >= settings.enroll_failures_per_hour

    def _record_failure(address: str) -> None:
        with store.registry() as s:
            s.add(EnrollFailure(address=address, at=now_iso()))

    @app.post("/v1/enroll")
    async def enroll(request: Request):
        if not _https_ok(request):
            raise Refused
        data = _json(await _body(request, 8 * 1024))
        code, key = data.get("code"), data.get("device_key")
        # Per address, with room for a whole school behind one address to
        # mistype. Guessing is stopped by the code itself (~59 random bits),
        # not by this limit.
        address = f"enroll|{_address(request)}"
        if _too_many_failures(address):
            return Response(status_code=429)
        role, box = data.get("role"), data.get("box_key")
        label = data.get("label") or ""
        if (
            not isinstance(code, str)
            or not isinstance(key, str)
            or not KEY.match(key)
            or role not in ROLES
            or (box is not None and (not isinstance(box, str) or not KEY.match(box)))
            or not isinstance(label, str)
        ):
            raise ValueError
        try:
            Ed25519PublicKey.from_public_bytes(unb64(key))
        except ValueError:
            raise ValueError
        now = datetime.now(timezone.utc)
        with store.registry() as s:
            row = s.get(EnrollmentCode, hash_code(code))
            expires = parse_iso(row.expires_at) if row else None
            ok = (
                row is not None
                and row.used_at is None
                and expires is not None
                and expires > now
                and row.role == role
            )
            existing = s.get(Device, key)
            if ok and existing is not None and existing.school_id != row.school_id:
                ok = False
            school = s.get(School, row.school_id) if ok else None
            if ok and (school is None or school.status != "active"):
                ok = False
            if ok:
                row.used_at = now.isoformat()
                if existing is None:
                    s.add(
                        Device(
                            key=key,
                            school_id=row.school_id,
                            role=role,
                            box_key=box,
                            label=label.strip()[:80],
                            recovers=row.recovers,
                            enrolled_at=now.isoformat(),
                        )
                    )
                else:
                    # Same school, enrolled again (e.g. with a recovery code).
                    existing.role = role
                    existing.status = "active"
                    existing.recovers = row.recovers
                school_id, school_name = row.school_id, school.name
        if not ok:
            _record_failure(address)
            return _not_found()
        store.school_audit(school_id, "device.enrolled", key, role)
        return {"school": {"name": school_name}, "role": role, "device_status": "active"}

    @app.post("/v1/enrollment-codes")
    async def enrollment_codes(request: Request):
        caller, body = await _signed(request)
        _require(caller, "admin")
        data = _json(body)
        role = data.get("role")
        hours = data.get("expires_hours", 72)
        recovers = data.get("learner_uuids") or []
        if (
            role not in ROLES
            or not isinstance(hours, int)
            or not isinstance(recovers, list)
            or len(recovers) > 60
            or not all(isinstance(u, str) and UUID_LIKE.match(u) for u in recovers)
        ):
            raise ValueError
        code = store.issue_code(caller.school_id, role, hours=hours, recovers=recovers)
        store.school_audit(
            caller.school_id,
            "code.issued",
            caller.device.key,
            f"{role}{' recovery' if recovers else ''}",
        )
        return {"code": code}

    @app.post("/v1/devices/revoke")
    async def revoke(request: Request):
        caller, body = await _signed(request)
        _require(caller, "admin")
        key = _json(body).get("device_key")
        if not isinstance(key, str) or not KEY.match(key):
            raise ValueError
        with store.registry() as s:
            device = s.get(Device, key)
            # Only a device of the caller's own school; anything else looks
            # exactly like an unknown device.
            if device is None or device.school_id != caller.school_id:
                raise Refused
            device.status = "revoked"
        store.school_audit(caller.school_id, "device.revoked", caller.device.key, key[:16])
        return {"device_key": key, "status": "revoked"}

    @app.get("/v1/devices")
    async def devices(request: Request):
        caller, _ = await _signed(request)
        _require(caller, "admin")
        with store.registry() as s:
            rows = s.scalars(
                select(Device).where(Device.school_id == caller.school_id)
            ).all()
            return {
                "devices": [
                    {
                        "device_key": d.key,
                        "role": d.role,
                        "label": d.label,
                        "status": d.status,
                        "enrolled_at": d.enrolled_at,
                    }
                    for d in rows
                ]
            }

    # ── Records ─────────────────────────────────────────────────────────

    def _accept(s, caller: Caller, record: dict) -> bool:
        rid, kind, payload = record.get("id"), record.get("kind"), record.get("payload")
        if not isinstance(rid, str) or not isinstance(payload, dict) or len(rid) > 140:
            return False
        role, key = caller.device.role, caller.device.key
        if kind == "assignment":
            if role not in ("teacher", "admin"):
                return False
            aid = payload.get("id")
            if not isinstance(aid, str) or rid != f"assignment:{aid}":
                return False
            row = s.get(AssignmentRecord, rid)
            if row is not None and row.publisher != key:
                return False  # publisher-authoritative
            text = json.dumps(payload)
            if row is None:
                s.add(
                    AssignmentRecord(id=rid, publisher=key, payload=text, updated_at=now_iso())
                )
            else:
                row.payload, row.updated_at = text, now_iso()
            return True
        if kind == "submission":
            uuid, member = payload.get("uuid"), payload.get("member")
            assignment = payload.get("assignment")
            learner = payload.get("learner_uuid")
            if (
                not isinstance(uuid, str)
                or not UUID_LIKE.match(uuid)
                or rid != f"submission:{uuid}"
                or not isinstance(member, str)
                or len(member) > 120
                or not isinstance(assignment, str)
                or (learner is not None and (not isinstance(learner, str) or not UUID_LIKE.match(learner)))
            ):
                return False
            if role == "learner" and not member.startswith(key[:16] + "/"):
                return False  # a learner device sends its own learners' work
            if s.get(SubmissionRecord, uuid) is None:
                s.add(
                    SubmissionRecord(
                        uuid=uuid,
                        assignment_id=assignment[:64],
                        member=member,
                        learner_uuid=learner,
                        payload=json.dumps(payload),
                        sent_by=key,
                        received_at=now_iso(),
                    )
                )
            return True  # append-only: a repeat is a no-op, never an edit
        if kind == "grade":
            if role not in ("teacher", "admin"):
                return False
            uuid, version, grade = payload.get("uuid"), payload.get("version"), payload.get("grade")
            if (
                not isinstance(uuid, str)
                or not UUID_LIKE.match(uuid)
                or not isinstance(version, int)
                or version <= 0
                or not isinstance(grade, int)
                or rid != f"grade:{uuid}:{version}"
            ):
                return False
            exists = s.scalar(
                select(GradeRecord).where(
                    GradeRecord.submission_uuid == uuid, GradeRecord.version == version
                )
            )
            if exists is None:
                feedback = payload.get("feedback")
                s.add(
                    GradeRecord(
                        submission_uuid=uuid,
                        version=version,
                        grade=grade,
                        feedback=feedback[:1000] if isinstance(feedback, str) else None,
                        graded_at=payload.get("graded_at") if isinstance(payload.get("graded_at"), str) else None,
                        sent_by=key,
                    )
                )
            return True
        return False

    @app.post("/v1/records")
    async def push_records(request: Request):
        caller, body = await _signed(request)
        records = _json(body).get("records")
        if not isinstance(records, list) or len(records) > MAX_RECORDS:
            raise ValueError
        accepted = []
        with store.school_session(caller.school_id) as s:
            for r in records:
                if isinstance(r, dict) and _accept(s, caller, r):
                    accepted.append(r["id"])
        return {"accepted": accepted}

    @app.get("/v1/records")
    async def pull_records(request: Request):
        caller, _ = await _signed(request)
        kind = request.query_params.get("kind")
        learner = request.query_params.get("learner_uuid", "")
        if kind != "submission" or not UUID_LIKE.match(learner):
            raise ValueError
        # The server doesn't know teaching assignments, so it can't tell
        # which learners a teacher teaches: only the Admin, and a device
        # enrolled with a recovery code naming this learner, may read back.
        role = caller.device.role
        if role == "teacher" or (
            role == "learner"
            and learner not in json.loads(caller.device.recovers or "[]")
        ):
            store.school_audit(
                caller.school_id, "refused.recovery", caller.device.key, ok=False
            )
            raise Refused
        with store.school_session(caller.school_id) as s:
            subs = s.scalars(
                select(SubmissionRecord).where(SubmissionRecord.learner_uuid == learner)
            ).all()
            out = []
            for sub in subs:
                best = s.scalar(
                    select(GradeRecord)
                    .where(GradeRecord.submission_uuid == sub.uuid)
                    .order_by(GradeRecord.version.desc())
                    .limit(1)
                )
                out.append(
                    {
                        "submission": json.loads(sub.payload),
                        "grade": None
                        if best is None
                        else {
                            "grade": best.grade,
                            "feedback": best.feedback,
                            "version": best.version,
                            "graded_at": best.graded_at,
                        },
                    }
                )
        return {"records": out}

    # ── Files ───────────────────────────────────────────────────────────

    @app.put("/v1/files/{sha}")
    async def put_file(sha: str, request: Request):
        if not SHA256.match(sha):
            raise Refused
        caller, body = await _signed(request, settings.max_file_bytes)
        _require(caller, "teacher", "admin")
        if hashlib.sha256(body).hexdigest() != sha:
            raise ValueError
        folder = store.files_dir(caller.school_id)
        target = folder / sha
        if not target.exists():
            tmp = folder / f"{sha}.{os.getpid()}.part"
            tmp.write_bytes(body)
            os.replace(tmp, target)
        with store.school_session(caller.school_id) as s:
            if s.get(FileRecord, sha) is None:
                s.add(FileRecord(sha256=sha, size=len(body), sent_by=caller.device.key, stored_at=now_iso()))
        return {"sha256": sha}

    @app.get("/v1/files/{sha}")
    async def get_file(sha: str, request: Request):
        if not SHA256.match(sha):
            raise Refused
        caller, _ = await _signed(request)
        with store.school_session(caller.school_id) as s:
            if s.get(FileRecord, sha) is None:
                raise Refused
        target = store.files_dir(caller.school_id) / sha
        if not target.is_file():
            raise Refused
        return Response(target.read_bytes(), media_type="application/pdf")

    # ── Teacher host backups ────────────────────────────────────────────

    #: Kept per device; older ones are dropped.
    keep_backups = 3

    @app.put("/v1/backups/host")
    async def put_backup(request: Request):
        caller, body = await _signed(request, settings.max_file_bytes)
        _require(caller, "teacher", "admin")
        data = _json(body)
        ledger = data.get("ledger")
        # Only a sealed ledger (a plain header plus AES-GCM nonce, ciphertext
        # and tag): never anything readable beyond the header.
        if (
            not isinstance(ledger, dict)
            or not set(ledger) <= LEDGER_KEYS
            or not {"kdf", "n", "c", "m"} <= set(ledger)
            or not all(isinstance(ledger[k], str) for k in ("n", "c", "m"))
        ):
            raise ValueError
        text = json.dumps(ledger)
        with store.school_session(caller.school_id) as s:
            s.add(
                HostBackup(
                    device=caller.device.key,
                    label=caller.device.label,
                    payload=text,
                    size=len(text),
                    at=now_iso(),
                )
            )
            s.flush()
            old = s.scalars(
                select(HostBackup)
                .where(HostBackup.device == caller.device.key)
                .order_by(HostBackup.id.desc())
                .offset(keep_backups)
            ).all()
            for row in old:
                s.delete(row)
        store.school_audit(caller.school_id, "backup.stored", caller.device.key)
        return {"stored": True}

    @app.get("/v1/backups/host")
    async def list_backups(request: Request):
        caller, _ = await _signed(request)
        _require(caller, "teacher", "admin")
        with store.school_session(caller.school_id) as s:
            rows = s.scalars(select(HostBackup).order_by(HostBackup.id.desc())).all()
            return {
                "backups": [
                    {"id": r.id, "label": r.label, "at": r.at, "size": r.size}
                    for r in rows
                ]
            }

    @app.get("/v1/backups/host/{backup_id}")
    async def get_backup(backup_id: int, request: Request):
        caller, _ = await _signed(request)
        _require(caller, "teacher", "admin")
        with store.school_session(caller.school_id) as s:
            row = s.get(HostBackup, backup_id)
            if row is None:
                raise Refused
            payload = json.loads(row.payload)
        store.school_audit(caller.school_id, "backup.downloaded", caller.device.key)
        return {"ledger": payload}

    return app
