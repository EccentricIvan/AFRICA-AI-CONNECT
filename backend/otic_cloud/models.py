"""Tables. The registry knows schools, devices and enrollment codes only;
every learner record lives in its school's own database."""

from __future__ import annotations

from sqlalchemy import (
    Boolean,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class RegistryBase(DeclarativeBase):
    pass


class SchoolBase(DeclarativeBase):
    pass


# ── Registry ────────────────────────────────────────────────────────────────


class Registration(RegistryBase):
    __tablename__ = "registrations"
    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    district: Mapped[str] = mapped_column(String(100))
    contact_name: Mapped[str] = mapped_column(String(120))
    contact_phone: Mapped[str] = mapped_column(String(40))
    emis_number: Mapped[str | None] = mapped_column(String(40), nullable=True)
    #: pending → approved | rejected
    status: Mapped[str] = mapped_column(String(20), default="pending")
    school_id: Mapped[str | None] = mapped_column(String(40), nullable=True)
    created_at: Mapped[str] = mapped_column(String(40))


class School(RegistryBase):
    __tablename__ = "schools"
    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    #: provisioning → active | suspended. Only active schools are served.
    status: Mapped[str] = mapped_column(String(20), default="provisioning")
    created_at: Mapped[str] = mapped_column(String(40))


class Device(RegistryBase):
    __tablename__ = "devices"
    #: Ed25519 public key, base64url without padding.
    key: Mapped[str] = mapped_column(String(64), primary_key=True)
    school_id: Mapped[str] = mapped_column(String(40), index=True)
    #: admin | teacher | learner
    role: Mapped[str] = mapped_column(String(10))
    box_key: Mapped[str | None] = mapped_column(String(64), nullable=True)
    label: Mapped[str] = mapped_column(String(80), default="")
    #: active | revoked
    status: Mapped[str] = mapped_column(String(10), default="active")
    #: JSON list of learner uuids this device may recover; "[]" for none.
    recovers: Mapped[str] = mapped_column(Text, default="[]")
    enrolled_at: Mapped[str] = mapped_column(String(40))


class EnrollmentCode(RegistryBase):
    __tablename__ = "enrollment_codes"
    #: SHA-256 of the code; the code itself is never stored.
    code_hash: Mapped[str] = mapped_column(String(64), primary_key=True)
    school_id: Mapped[str] = mapped_column(String(40))
    role: Mapped[str] = mapped_column(String(10))
    recovers: Mapped[str] = mapped_column(Text, default="[]")
    expires_at: Mapped[str] = mapped_column(String(40))
    used_at: Mapped[str | None] = mapped_column(String(40), nullable=True)


class EnrollFailure(RegistryBase):
    __tablename__ = "enroll_failures"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    address: Mapped[str] = mapped_column(String(64), index=True)
    at: Mapped[str] = mapped_column(String(40))


class OperatorAudit(RegistryBase):
    """Operator actions, and refusals that named no school (unknown
    device). Never codes, signatures or anything a learner wrote."""

    __tablename__ = "operator_audit"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    at: Mapped[str] = mapped_column(String(40))
    action: Mapped[str] = mapped_column(String(60))
    detail: Mapped[str] = mapped_column(String(300), default="")


# ── One school ──────────────────────────────────────────────────────────────


class SchoolMeta(SchoolBase):
    """One row naming the school this database belongs to, written at
    provisioning: every request checks it before touching a record."""

    __tablename__ = "school_meta"
    school_id: Mapped[str] = mapped_column(String(40), primary_key=True)


class AssignmentRecord(SchoolBase):
    __tablename__ = "assignments"
    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    publisher: Mapped[str] = mapped_column(String(64))
    payload: Mapped[str] = mapped_column(Text)
    updated_at: Mapped[str] = mapped_column(String(40))


class SubmissionRecord(SchoolBase):
    """Append-only: a submission is written once and never changed."""

    __tablename__ = "submissions"
    uuid: Mapped[str] = mapped_column(String(64), primary_key=True)
    assignment_id: Mapped[str] = mapped_column(String(64), index=True)
    member: Mapped[str] = mapped_column(String(120))
    learner_uuid: Mapped[str | None] = mapped_column(String(64), index=True, nullable=True)
    payload: Mapped[str] = mapped_column(Text)
    sent_by: Mapped[str] = mapped_column(String(64))
    received_at: Mapped[str] = mapped_column(String(40))


class GradeRecord(SchoolBase):
    __tablename__ = "grades"
    __table_args__ = (UniqueConstraint("submission_uuid", "version"),)
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    submission_uuid: Mapped[str] = mapped_column(String(64), index=True)
    version: Mapped[int] = mapped_column(Integer)
    grade: Mapped[int] = mapped_column(Integer)
    feedback: Mapped[str | None] = mapped_column(Text, nullable=True)
    graded_at: Mapped[str | None] = mapped_column(String(40), nullable=True)
    sent_by: Mapped[str] = mapped_column(String(64))


class FileRecord(SchoolBase):
    __tablename__ = "files"
    sha256: Mapped[str] = mapped_column(String(64), primary_key=True)
    size: Mapped[int] = mapped_column(Integer)
    sent_by: Mapped[str] = mapped_column(String(64))
    stored_at: Mapped[str] = mapped_column(String(40))


class Nonce(SchoolBase):
    __tablename__ = "nonces"
    device: Mapped[str] = mapped_column(String(64), primary_key=True)
    nonce: Mapped[str] = mapped_column(String(64), primary_key=True)
    at: Mapped[str] = mapped_column(String(40), index=True)


class SchoolAudit(SchoolBase):
    """Enrollments, revocations, codes issued and refusals by this school's
    devices. Never codes, signatures, PINs or answer text."""

    __tablename__ = "audit"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    at: Mapped[str] = mapped_column(String(40))
    device: Mapped[str] = mapped_column(String(16), default="")
    action: Mapped[str] = mapped_column(String(60))
    detail: Mapped[str] = mapped_column(String(300), default="")
    ok: Mapped[bool] = mapped_column(Boolean, default=True)
