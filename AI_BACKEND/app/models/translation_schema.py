from pydantic import BaseModel


class TranslationRequest(BaseModel):
    source_language: str
    target_language: str
    text: str


class TranslationResponse(BaseModel):
    source_language: str
    target_language: str
    original_text: str
    translated_text: str