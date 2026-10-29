"""`uvicorn otic_cloud.main:app` — settings from the environment
(OTIC_DATA_DIR, OTIC_SCHOOL_DB_URL, OTIC_ALLOW_HTTP)."""

from .api import create_app

app = create_app()
