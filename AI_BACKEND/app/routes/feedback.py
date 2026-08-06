from fastapi import APIRouter, HTTPException, status

from app.feedback_store import save_feedback
from app.schemas import FeedbackRequest, FeedbackResponse

router = APIRouter(prefix="/feedback", tags=["Feedback"])


@router.post("", response_model=FeedbackResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=FeedbackResponse, status_code=status.HTTP_201_CREATED, include_in_schema=False)
def record_feedback(request: FeedbackRequest) -> FeedbackResponse:
    try:
        save_feedback(request)
    except OSError as exc:
        raise HTTPException(status_code=500, detail="Could not save feedback") from exc
    return FeedbackResponse(status="success", message="Feedback saved for review.")
