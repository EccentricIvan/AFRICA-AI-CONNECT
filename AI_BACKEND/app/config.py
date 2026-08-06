"""Load local development settings without overriding real environment variables."""
import logging
import os
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env", override=False)

logger = logging.getLogger(__name__)


def get_groq_api_key() -> str | None:
    """Return a normalized credential without ever logging its value."""
    value = os.getenv("GROQ_API_KEY")
    if value is None or not value.strip():
        return None
    return value.strip()


def validate_provider_configuration() -> bool:
    configured = get_groq_api_key() is not None
    logger.info("Groq provider configuration is %s", "present" if configured else "missing")
    return configured
