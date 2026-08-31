from pydantic import BaseModel


class ChatRequest(BaseModel):
    language: str
    message: str


class ChatResponse(BaseModel):
    language: str
    response: str