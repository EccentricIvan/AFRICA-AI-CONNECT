from __future__ import annotations

import base64
import json
import secrets
from datetime import datetime, timezone

import pytest
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from fastapi.testclient import TestClient

from otic_cloud.api import create_app, signed_bytes
from otic_cloud.config import Settings


def b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")


class DeviceClient:
    """A device: its own Ed25519 key, signing every request like the app."""

    def __init__(self, client: TestClient):
        self.client = client
        self.private = Ed25519PrivateKey.generate()
        self.key = b64(
            self.private.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw)
        )

    def enroll(self, code: str, role: str, **extra):
        return self.client.post(
            "/v1/enroll",
            json={"code": code, "device_key": self.key, "role": role, **extra},
        )

    def headers(self, method: str, path: str, body: bytes, *, nonce=None, time=None):
        time = time or datetime.now(timezone.utc).isoformat()
        nonce = nonce or b64(secrets.token_bytes(18))
        sig = self.private.sign(signed_bytes(method, path, time, nonce, body))
        return {
            "X-Otic-Device": self.key,
            "X-Otic-Time": time,
            "X-Otic-Nonce": nonce,
            "X-Otic-Sig": b64(sig),
            "Content-Type": "application/json",
        }

    def request(self, method: str, path: str, data=None, raw: bytes | None = None, **kw):
        body = raw if raw is not None else (b"" if data is None else json.dumps(data).encode())
        return self.client.request(
            method, path, content=body, headers=self.headers(method, path, body, **kw)
        )

    def post(self, path, data=None, **kw):
        return self.request("POST", path, data, **kw)

    def get(self, path, **kw):
        return self.request("GET", path, **kw)


@pytest.fixture
def settings(tmp_path):
    return Settings(data_dir=tmp_path, allow_http=True)


@pytest.fixture
def app(settings):
    return create_app(settings)


@pytest.fixture
def client(app):
    return TestClient(app)


def provision(client: TestClient, name: str) -> tuple[str, str]:
    """Registers and approves a school; returns its id and Admin code."""
    reg = client.post(
        "/v1/schools/register",
        json={
            "name": name,
            "district": "Kampala",
            "contact_name": "Head",
            "contact_phone": "+256700000000",
        },
    ).json()
    return client.app.state.store.approve(reg["registration_id"])


@pytest.fixture
def two_schools(client):
    """School A and School B, each with an Admin, a teacher and a learner
    device enrolled."""
    out = {}
    for name in ("A", "B"):
        school_id, admin_code = provision(client, f"School {name}")
        admin = DeviceClient(client)
        assert admin.enroll(admin_code, "admin").status_code == 200
        teacher, learner = DeviceClient(client), DeviceClient(client)
        code = admin.post("/v1/enrollment-codes", {"role": "teacher"}).json()["code"]
        assert teacher.enroll(code, "teacher").status_code == 200
        code = admin.post("/v1/enrollment-codes", {"role": "learner"}).json()["code"]
        assert learner.enroll(code, "learner").status_code == 200
        out[name] = {
            "id": school_id,
            "admin": admin,
            "teacher": teacher,
            "learner": learner,
        }
    return out
