"""Context-aware chat service using an OpenAI-compatible Groq endpoint."""
import os
from dataclasses import dataclass

import requests

from app.translator import translator
from app.services.sunbird_service import SunbirdError, sunbird_service

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
LANGUAGE_ALIASES = {
    "en": "eng", "eng": "eng", "english": "eng",
    "lg": "lug", "lug": "lug", "luganda": "lug",
    "sw": "swa", "swa": "swa", "swh": "swa", "swahili": "swa", "kiswahili": "swa",
}


@dataclass(frozen=True)
class ChatResult:
    response: str
    provider: str


class ChatService:
    def chat(self, message: str, language: str, context: list[str] | None = None) -> ChatResult:
        language_code = LANGUAGE_ALIASES.get(language.strip().lower())
        if language_code is None:
            raise ValueError("language must be English, Luganda, or Swahili")

        if language_code in {"lug", "swa"} and sunbird_service.is_configured:
            try:
                return ChatResult(sunbird_service.chat(message, language_code, context), "sunbird")
            except SunbirdError:
                # Continue through the existing Groq + local translation fallback.
                pass

        api_key = os.getenv("GROQ_API_KEY")
        if not api_key:
            raise RuntimeError("GROQ_API_KEY is not configured")

        messages = [{
            "role": "system",
            "content": (
                "You are OTIC CONNECT, a concise and practical assistant for African youth. "
                "Use prior context when it is relevant. Answer in clear English."
            ),
        }]
        for item in (context or [])[-20:]:
            if item.strip():
                messages.append({"role": "user", "content": item.strip()})
        messages.append({"role": "user", "content": message.strip()})

        try:
            response = requests.post(
                GROQ_API_URL,
                headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                json={
                    "model": os.getenv("GROQ_MODEL", "llama-3.1-8b-instant"),
                    "messages": messages,
                    "temperature": 0.35,
                    "max_tokens": 420,
                },
                timeout=45,
            )
            response.raise_for_status()
            answer = response.json()["choices"][0]["message"]["content"].strip()
        except (requests.RequestException, KeyError, IndexError, TypeError, ValueError) as exc:
            raise RuntimeError(f"Chat provider request failed: {exc}") from exc

        if language_code == "eng":
            return ChatResult(answer, "groq")
        return ChatResult(translator.translate(answer, language_code), "groq+translation")


chat_service = ChatService()
