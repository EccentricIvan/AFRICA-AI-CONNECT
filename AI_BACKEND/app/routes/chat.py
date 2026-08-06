import logging

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import JSONResponse

from app.schemas import ChatRequest, ChatResponse
from app.services.chat_service import ChatProviderError, chat_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("", response_model=ChatResponse)
@router.post("/", response_model=ChatResponse, include_in_schema=False)
def chat(request: ChatRequest) -> ChatResponse:
    try:
        result = chat_service.chat(request.message, request.language, request.context)
        return ChatResponse(
            language=request.language, response=result.response, provider=result.provider
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except ChatProviderError as exc:
        logger.warning("Chat provider failure: code=%s retryable=%s", exc.code, exc.retryable)
        status_code = (
            status.HTTP_503_SERVICE_UNAVAILABLE
            if exc.retryable else status.HTTP_502_BAD_GATEWAY
        )
        return JSONResponse(
            status_code=status_code,
            content={"error": {"code": exc.code, "retryable": exc.retryable}},
        )
    except RuntimeError as exc:
        logger.exception("Unexpected chat service failure")
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"error": {"code": "CHAT_PROVIDER_UNAVAILABLE", "retryable": True}},
        )
