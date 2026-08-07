"""API request and response schemas."""
from typing import Literal

from pydantic import BaseModel, Field


class TranslationRequest(BaseModel):
    text: str = Field(min_length=1, max_length=5000)
    target_lang: str = Field(pattern=r"^(lug|swa|nyn|teo|nyo|ach)$", examples=["lug"])


class TranslationResponse(BaseModel):
    original_text: str
    translated_text: str
    target_lang: str
    confidence: float | None = Field(default=None, ge=0.0, le=1.0)
    meaning_similarity: float | None = Field(default=None, ge=0.0, le=1.0)
    correction_source: str
    alternatives_evaluated: int = Field(ge=0)


class ChatHistoryMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=5000)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=5000)
    language: str = Field(default="eng", examples=["lug", "swa", "eng"])
    # Strings remain accepted for compatibility with already-installed APKs.
    context: list[ChatHistoryMessage | str] = Field(default_factory=list, max_length=20)


class ChatResponse(BaseModel):
    language: str
    response: str
    provider: str


class FeedbackRequest(BaseModel):
    language: str = Field(min_length=2, max_length=32)
    user_message: str = Field(min_length=1, max_length=5000)
    ai_response: str = Field(min_length=1, max_length=5000)
    correct_response: str = Field(min_length=1, max_length=5000)
    issue_type: str = Field(default="translation", max_length=100)
    reviewer: str = Field(default="anonymous", max_length=100)
    approved: bool = False


class FeedbackResponse(BaseModel):
    status: str
    message: str
