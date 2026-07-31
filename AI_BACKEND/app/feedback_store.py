"""Durable local CSV storage for reviewed model corrections."""
import csv
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock

from app.schemas import FeedbackRequest

DATA_DIR = Path(__file__).resolve().parent / "Data"
CORRECTIONS_FILE = DATA_DIR / "corrections.csv"
FIELDNAMES = (
    "timestamp", "language", "user_message", "ai_response",
    "correct_response", "issue_type", "reviewer", "approved",
)
_write_lock = Lock()


def save_feedback(feedback: FeedbackRequest) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with _write_lock:
        needs_header = not CORRECTIONS_FILE.exists() or CORRECTIONS_FILE.stat().st_size == 0
        with CORRECTIONS_FILE.open("a", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=FIELDNAMES)
            if needs_header:
                writer.writeheader()
            writer.writerow({
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "language": feedback.language.strip().lower(),
                "user_message": feedback.user_message.strip(),
                "ai_response": feedback.ai_response.strip(),
                "correct_response": feedback.correct_response.strip(),
                "issue_type": feedback.issue_type.strip(),
                "reviewer": feedback.reviewer.strip(),
                "approved": "yes" if feedback.approved else "no",
            })
