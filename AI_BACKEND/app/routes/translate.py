from fastapi import APIRouter, HTTPException, status

from app.schemas import TranslationRequest, TranslationResponse
from app.translator import translator

router = APIRouter(prefix="/translate", tags=["Translation"])


@router.post("", response_model=TranslationResponse)
@router.post("/", response_model=TranslationResponse, include_in_schema=False)
def translate_text(request: TranslationRequest) -> TranslationResponse:
    try:
        result = translator.translate_detailed(request.text, request.target_lang)
        return TranslationResponse(
            original_text=request.text,
            translated_text=result.text,
            target_lang=request.target_lang,
            confidence=result.confidence,
            meaning_similarity=result.meaning_similarity,
            correction_source=result.source,
            alternatives_evaluated=result.alternatives_evaluated,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except (FileNotFoundError, RuntimeError) as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc
