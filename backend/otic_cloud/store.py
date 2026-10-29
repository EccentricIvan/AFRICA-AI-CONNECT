"""The registry, each school's own database, and provisioning.

A school's records are reached only through `Store.school_session`, which
opens that school's own engine (its own SQLite file, or its own Postgres
database and role in production) and checks the database's `school_meta`
row names the same school before returning. No engine, session or
connection is ever shared between schools, so a query bug, a pooled
connection or a wrong id can reach one school's data at most — and only
the school the signed device belongs to.
"""

from __future__ import annotations

import hashlib
import json
import re
import secrets
import threading
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from typing import Iterator

from sqlalchemy import create_engine, event, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from .config import Settings
from .models import (
    EnrollmentCode,
    OperatorAudit,
    Registration,
    RegistryBase,
    School,
    SchoolAudit,
    SchoolBase,
    SchoolMeta,
)

SCHOOL_ID = re.compile(r"^sch_[0-9a-f]{32}$")

#: Enrollment code alphabet: no 0/O, 1/I/L.
_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_iso(value: str) -> datetime | None:
    try:
        t = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        return None
    return t if t.tzinfo else t.replace(tzinfo=timezone.utc)


def hash_code(code: str) -> str:
    normal = code.replace("-", "").replace(" ", "").upper()
    return hashlib.sha256(normal.encode()).hexdigest()


def new_code() -> str:
    raw = "".join(secrets.choice(_CODE_ALPHABET) for _ in range(12))
    return "-".join(raw[i : i + 4] for i in range(0, 12, 4))


class IsolationError(RuntimeError):
    """A school database that doesn't belong to the school asked for."""


def _sqlite_pragmas(engine: Engine) -> None:
    if engine.url.get_backend_name() != "sqlite":
        return

    @event.listens_for(engine, "connect")
    def _on_connect(dbapi_conn, _):  # pragma: no cover - driver hook
        cur = dbapi_conn.cursor()
        cur.execute("PRAGMA journal_mode=WAL")
        cur.execute("PRAGMA foreign_keys=ON")
        cur.close()


class Store:
    def __init__(self, settings: Settings):
        self.settings = settings
        settings.data_dir.mkdir(parents=True, exist_ok=True)
        self.registry_engine = create_engine(settings.registry_url)
        _sqlite_pragmas(self.registry_engine)
        RegistryBase.metadata.create_all(self.registry_engine)
        self._registry = sessionmaker(self.registry_engine, expire_on_commit=False)
        self._engines: dict[str, Engine] = {}
        self._lock = threading.Lock()

    # ── Registry ────────────────────────────────────────────────────────

    @contextmanager
    def registry(self) -> Iterator[Session]:
        with self._registry() as s, s.begin():
            yield s

    def operator_audit(self, action: str, detail: str = "") -> None:
        with self.registry() as s:
            s.add(OperatorAudit(at=now_iso(), action=action, detail=detail[:300]))

    # ── One school ──────────────────────────────────────────────────────

    def _engine(self, school_id: str) -> Engine:
        if not SCHOOL_ID.match(school_id):
            raise IsolationError("not a school id")
        with self._lock:
            engine = self._engines.get(school_id)
            if engine is None:
                folder = self.settings.school_folder(school_id)
                folder.mkdir(parents=True, exist_ok=True)
                engine = create_engine(self.settings.school_url(school_id))
                _sqlite_pragmas(engine)
                self._engines[school_id] = engine
            return engine

    @contextmanager
    def school_session(self, school_id: str) -> Iterator[Session]:
        """A transaction on [school_id]'s own database, after checking the
        database says it is that school's."""
        engine = self._engine(school_id)
        with Session(engine, expire_on_commit=False) as s, s.begin():
            meta = s.scalars(select(SchoolMeta)).all()
            if [m.school_id for m in meta] != [school_id]:
                raise IsolationError(f"database of {school_id} is not its own")
            yield s

    def school_audit(
        self, school_id: str, action: str, device: str = "", detail: str = "", ok=True
    ) -> None:
        with self.school_session(school_id) as s:
            s.add(
                SchoolAudit(
                    at=now_iso(),
                    device=device[:16],
                    action=action,
                    detail=detail[:300],
                    ok=ok,
                )
            )

    def files_dir(self, school_id: str):
        if not SCHOOL_ID.match(school_id):
            raise IsolationError("not a school id")
        d = self.settings.school_folder(school_id) / "files"
        d.mkdir(parents=True, exist_ok=True)
        return d

    # ── Registration and provisioning ───────────────────────────────────

    def register(self, **fields) -> str:
        rid = "reg_" + secrets.token_hex(12)
        with self.registry() as s:
            s.add(Registration(id=rid, created_at=now_iso(), **fields))
        return rid

    def approve(self, registration_id: str) -> tuple[str, str]:
        """Provisions the school of a pending registration. Returns its id
        and the first Admin enrollment code (shown once). The school is
        served only once every step, including the isolation check, passed."""
        with self.registry() as s:
            reg = s.get(Registration, registration_id)
            if reg is None or reg.status != "pending":
                raise ValueError("no pending registration with that id")
            school_id = "sch_" + secrets.token_hex(16)
            reg.status = "approved"
            reg.school_id = school_id
            s.add(School(id=school_id, name=reg.name, created_at=now_iso()))
        self.operator_audit("school.provisioning", school_id)

        engine = self._engine(school_id)
        SchoolBase.metadata.create_all(engine)
        with Session(engine) as s, s.begin():
            s.add(SchoolMeta(school_id=school_id))
        self.check_isolation(school_id)
        code = self.issue_code(school_id, "admin", hours=24 * 7)
        with self.registry() as s:
            s.get(School, school_id).status = "active"
        self.operator_audit("school.active", school_id)
        self.school_audit(school_id, "school.provisioned")
        return school_id, code

    def check_isolation(self, school_id: str) -> None:
        """The new school's database names only it, holds no records, and
        is a different database from every other school's."""
        from .models import AssignmentRecord, SubmissionRecord

        with self.school_session(school_id) as s:
            if s.scalars(select(SubmissionRecord)).first() is not None:
                raise IsolationError("a new school already has records")
            if s.scalars(select(AssignmentRecord)).first() is not None:
                raise IsolationError("a new school already has records")
        mine = str(self._engine(school_id).url)
        with self.registry() as s:
            others = [x.id for x in s.scalars(select(School)) if x.id != school_id]
        for other in others:
            if str(self._engine(other).url) == mine:
                raise IsolationError(f"{school_id} shares a database with {other}")

    def issue_code(
        self,
        school_id: str,
        role: str,
        hours: int = 72,
        recovers: list[str] | None = None,
    ) -> str:
        if role not in ("admin", "teacher", "learner"):
            raise ValueError("unknown role")
        code = new_code()
        expires = datetime.now(timezone.utc) + timedelta(hours=max(1, min(hours, 168)))
        with self.registry() as s:
            s.add(
                EnrollmentCode(
                    code_hash=hash_code(code),
                    school_id=school_id,
                    role=role,
                    recovers=json.dumps(recovers or []),
                    expires_at=expires.isoformat(),
                )
            )
        return code
