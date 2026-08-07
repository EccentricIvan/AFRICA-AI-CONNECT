"""FastAPI application entry point for OTIC-CONNECT."""
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.chat import router as chat_router
from app.routes.feedback import router as feedback_router
from app.routes.translate import router as translate_router
from app.translator import translator
from app.services.sunbird_service import sunbird_service
from app.config import get_groq_api_key, validate_provider_configuration

app = FastAPI(
    title="OTIC-CONNECT API",
    version="1.0.0",
    description="Local language translation, contextual chat, and correction feedback.",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(translate_router)
app.include_router(chat_router)
app.include_router(feedback_router)


@app.on_event("startup")
def validate_startup_configuration() -> None:
    # Missing Groq configuration is reported safely; Sunbird/local translation
    # endpoints can still operate, so the whole API is not terminated.
    validate_provider_configuration()
    # Resolve this at startup so an invalid model name fails before traffic.
    sunbird_service.chat_model


@app.get("/", tags=["System"])
def root() -> dict:
    return {
        "name": "OTIC-CONNECT API",
        "version": app.version,
        "docs": "/docs",
        "endpoints": ["/translate", "/chat", "/feedback", "/health"],
    }


@app.get("/health", tags=["System"])
def health() -> dict:
    payload = {
        "status": "ok",
        "translation_provider": "sunbird" if sunbird_service.is_configured else "local_lora",
        "sunbird_status": "configured" if sunbird_service.is_configured else "not_configured",
        "sunbird_chat_model": sunbird_service.chat_model,
        "chat_pipeline": "sunbird_translate+groq+sunbird_translate",
        "groq_status": "configured" if get_groq_api_key() else "not_configured",
        "local_model_status": "loaded" if translator.is_initialized else "standby",
        "local_model_device": str(translator.device),
    }
    if translator.load_error:
        payload["model_error"] = translator.load_error
    return payload
