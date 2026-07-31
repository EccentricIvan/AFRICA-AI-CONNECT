"""Client for Sunbird AI translation and multilingual chat APIs."""
from __future__ import annotations

import os
from typing import Any

import requests

import app.config  # noqa: F401  # Load AI_BACKEND/.env before reading settings.

SUNBIRD_BASE_URL = os.getenv("SUNBIRD_BASE_URL", "https://api.sunbird.ai/tasks").rstrip("/")
SUPPORTED_LANGUAGES = {"lug", "swa"}


class SunbirdError(RuntimeError):
    pass


class SunbirdService:
    @property
    def token(self) -> str | None:
        return os.getenv("SUNBIRD_API_TOKEN") or os.getenv("AUTH_TOKEN")

    @property
    def is_configured(self) -> bool:
        return bool(self.token)

    def _post(self, endpoint: str, payload: dict[str, Any], timeout: int = 60) -> dict[str, Any]:
        token = self.token
        if not token:
            raise SunbirdError("SUNBIRD_API_TOKEN is not configured")
        try:
            response = requests.post(
                f"{SUNBIRD_BASE_URL}/{endpoint.lstrip('/')}",
                headers={
                    "Accept": "application/json",
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json",
                },
                json=payload,
                timeout=timeout,
            )
            response.raise_for_status()
            data = response.json()
        except requests.RequestException as exc:
            raise SunbirdError(f"Sunbird request failed: {exc}") from exc
        except ValueError as exc:
            raise SunbirdError("Sunbird returned invalid JSON") from exc
        if not isinstance(data, dict):
            raise SunbirdError("Sunbird returned an unexpected response")
        return data

    def translate(self, text: str, target_language: str) -> str:
        if target_language not in SUPPORTED_LANGUAGES:
            raise ValueError("Sunbird target language must be 'lug' or 'swa'")
        data = self._post(
            "translate",
            {"source_language": "eng", "target_language": target_language, "text": text},
        )
        output = data.get("output", {})
        translated = output.get("translated_text") if isinstance(output, dict) else None
        if not isinstance(translated, str) or not translated.strip():
            raise SunbirdError("Sunbird returned no translated text")
        return translated.strip()

    def chat(
        self, message: str, language: str,
        context: list[dict[str, str]] | None = None, *,
        system_prompt: str | None = None, correction_prompt: str | None = None,
    ) -> str:
        if language not in SUPPORTED_LANGUAGES:
            raise ValueError("Sunbird chat language must be 'lug' or 'swa'")
        messages: list[dict[str, str]] = [{
            "role": "system",
            "content": system_prompt or "Reply naturally in the selected language.",
        }]
        for item in (context or [])[-20:]:
            role = item.get("role")
            content = item.get("content", "").strip()
            if role in {"user", "assistant"} and content:
                messages.append({"role": role, "content": content})
        messages.append({"role": "user", "content": message.strip()})
        if correction_prompt:
            messages.append({"role": "system", "content": correction_prompt})
        data = self._post(
            "chat/completions",
            {
                "model": os.getenv("SUNBIRD_CHAT_MODEL", "sunflower-14b"),
                "messages": messages,
                "temperature": 0.5,
                "max_tokens": 650,
            },
            timeout=90,
        )
        try:
            reply = data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError) as exc:
            raise SunbirdError("Sunbird returned no chat response") from exc
        if not isinstance(reply, str) or not reply.strip():
            raise SunbirdError("Sunbird returned an empty chat response")
        return reply.strip()


sunbird_service = SunbirdService()
