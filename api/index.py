import os
from typing import Literal

import requests
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


LanguageCode = Literal["en", "lg", "sw", "nyn", "nyo", "ach", "teo"]

LANGUAGE_NAMES = {
    "en": "English",
    "lg": "Luganda",
    "sw": "Kiswahili",
    "nyn": "Runyankore",
    "nyo": "Runyoro",
    "ach": "Acholi",
    "teo": "Ateso",
}

SUNBIRD_CODES = {
    "lg": "lug",
    "sw": "swa",
    "nyn": "nyn",
    "nyo": "nyo",
    "ach": "ach",
    "teo": "teo",
}

app = FastAPI(
    title="AI Connect Africa API",
    version="1.0.0",
    description="Lightweight synchronized chat backend for AI Connect Africa",
)

allowed_origins = [
    origin.strip()
    for origin in os.getenv("ALLOWED_ORIGINS", "*").split(",")
    if origin.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=allowed_origins != ["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    language: LanguageCode = "en"
    history: list["ChatMessage"] = Field(default_factory=list, max_length=20)


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=4000)


def _health_payload() -> dict:
    sunbird_configured = bool(
        os.getenv("SUNBIRD_API_TOKEN") or os.getenv("AUTH_TOKEN")
    )
    return {
        "status": "ok",
        "service": "africa-ai-connect-api",
        "version": "1.0.0",
        "supported_languages": list(LANGUAGE_NAMES),
        "translation_provider": "sunbird" if sunbird_configured else "unconfigured",
        "sunbird_status": "configured" if sunbird_configured else "not_configured",
        "chat_pipeline": "sunbird_translate+groq+sunbird_translate",
        "groq_status": "configured" if os.getenv("GROQ_API_KEY") else "not_configured",
    }


@app.get("/")
@app.get("/health")
@app.get("/api/health")
def health() -> dict:
    return _health_payload()


def _sunbird_translate(text: str, target: str, source: str) -> str:
    token = (os.getenv("SUNBIRD_API_TOKEN") or os.getenv("AUTH_TOKEN") or "").strip()
    if not token:
        raise HTTPException(status_code=503, detail="Translation service is not configured")

    base_url = os.getenv("SUNBIRD_BASE_URL", "https://api.sunbird.ai/tasks").rstrip("/")
    try:
        response = requests.post(
            f"{base_url}/translate",
            headers={
                "Accept": "application/json",
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            json={
                "source_language": source,
                "target_language": target,
                "text": text,
            },
            timeout=20,
        )
        response.raise_for_status()
        output = response.json().get("output", {})
        translated = output.get("translated_text")
    except (requests.RequestException, AttributeError, ValueError) as error:
        raise HTTPException(status_code=502, detail="Translation service unavailable") from error

    if not isinstance(translated, str) or not translated.strip():
        raise HTTPException(status_code=502, detail="Translation service returned no text")
    return translated.strip()


def _groq_chat(message: str, history: list[ChatMessage], system_prompt: str) -> str:
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(status_code=503, detail="Chat service is not configured")

    try:
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile"),
                "messages": [
                    {"role": "system", "content": system_prompt},
                    *[
                        {"role": item.role, "content": item.content}
                        for item in history[-12:]
                    ],
                    {"role": "user", "content": message.strip()},
                ],
                "temperature": 0.5,
                "max_tokens": 512,
            },
            timeout=20,
        )
        response.raise_for_status()
        reply = response.json()["choices"][0]["message"]["content"].strip()
    except (requests.RequestException, KeyError, IndexError, TypeError) as error:
        raise HTTPException(status_code=502, detail="AI provider unavailable") from error

    if not reply:
        raise HTTPException(status_code=502, detail="AI provider returned no text")
    return reply


@app.post("/chat")
@app.post("/chat/")
@app.post("/api/chat")
@app.post("/api/chat/")
def chat(request: ChatRequest) -> dict:
    language = LANGUAGE_NAMES[request.language]
    system_prompt = (
        "You are AI Connect Africa, a warm and practical assistant for women "
        "in Sub-Saharan Africa. Help with business, agriculture, financial "
        "literacy, health, digital skills, jobs, leadership, and wellbeing. "
        f"Always answer in clear, natural {language}. Do not change language "
        "unless the user asks. Keep the answer concise and actionable. For "
        "serious health or safety concerns, advise contacting a qualified local "
        "professional or emergency service."
    )

    provider = "groq"
    if request.language == "en":
        reply = _groq_chat(request.message, request.history, system_prompt)
    else:
        sunbird_code = SUNBIRD_CODES[request.language]
        transcript = "\n".join(
            [
                *[
                    f"{item.role.upper()}: {item.content}"
                    for item in request.history[-12:]
                ],
                f"USER: {request.message.strip()}",
            ]
        )
        english_transcript = _sunbird_translate(transcript, "eng", sunbird_code)
        english_prompt = (
            "The following is an English translation of a conversation. Answer the "
            "latest USER request in clear English, using earlier turns for context. "
            "Preserve every amount, place, constraint, and requested quantity. Give "
            "practical East African advice and do not invent institutions or amounts.\n\n"
            f"{english_transcript}"
        )
        english_system_prompt = (
            "You are AI Connect Africa, a warm and practical assistant for women "
            "in Sub-Saharan Africa. Answer in clear English with concise, actionable "
            "advice. Be culturally sensitive and preserve the user's exact constraints."
        )
        english_reply = _groq_chat(english_prompt, [], english_system_prompt)
        reply = _sunbird_translate(english_reply, sunbird_code, "eng")
        provider = "sunbird+groq+sunbird"

    return {
        "language": request.language,
        "response": reply,
        "reply": reply,
        "provider": provider,
        "source": f"vercel-{provider}",
    }
