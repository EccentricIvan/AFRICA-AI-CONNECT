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

app = FastAPI(
    title="Africa AI Connect API",
    version="1.0.0",
    description="Lightweight synchronized chat backend for Africa AI Connect",
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
    return {
        "status": "ok",
        "service": "africa-ai-connect-api",
        "version": "1.0.0",
        "supported_languages": list(LANGUAGE_NAMES),
    }


@app.get("/")
@app.get("/health")
@app.get("/api/health")
def health() -> dict:
    return _health_payload()


@app.post("/chat")
@app.post("/chat/")
@app.post("/api/chat")
@app.post("/api/chat/")
def chat(request: ChatRequest) -> dict:
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(status_code=503, detail="Chat service is not configured")

    language = LANGUAGE_NAMES[request.language]
    system_prompt = (
        "You are Africa AI Connect, a warm and practical assistant for women "
        "in Sub-Saharan Africa. Help with business, agriculture, financial "
        "literacy, health, digital skills, jobs, leadership, and wellbeing. "
        f"Always answer in clear, natural {language}. Do not change language "
        "unless the user asks. Keep the answer concise and actionable. For "
        "serious health or safety concerns, advise contacting a qualified local "
        "professional or emergency service."
    )

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
                        for item in request.history[-12:]
                    ],
                    {"role": "user", "content": request.message.strip()},
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

    return {
        "language": request.language,
        "response": reply,
        "reply": reply,
        "source": "vercel-groq",
    }
