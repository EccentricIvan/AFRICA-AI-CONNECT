from pydantic import BaseModel


class FeedbackRequest(BaseModel):
    language: str
    user_message: str
    ai_response: str
    correct_response: str = ""
    issue_type: str = "needs review"
    reviewer: str = "pending"


class FeedbackResponse(BaseModel):
    status: str
    message: str