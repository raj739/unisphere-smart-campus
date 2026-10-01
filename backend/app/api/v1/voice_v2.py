import logging
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.ai_interaction_v2 import AIInteractionV2
from app.models.student import Student
from app.schemas.voice_v2 import (
    VoiceChatRequestV2,
    VoiceChatResponseV2,
)
from app.services.ai_context_service import build_student_context
from app.services.ai_prompt_service import build_ai_system_prompt
from app.services.gemini_service import GeminiService
from app.services.grounded_assistant_service import answer_student_question
from app.services.ai_language_service import (
    language_label,
    localize_grounded_answer,
    resolve_language,
)
from app.services.general_information_service import answer_general_question
from app.services.rag_service import search_knowledge


router = APIRouter(
    prefix="/voice-v2",
    tags=["Voice Assistant"],
)

logger = logging.getLogger(__name__)


@router.post(
    "/chat",
    response_model=VoiceChatResponseV2,
)
async def voice_chat(
    payload: VoiceChatRequestV2,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = (
        db.query(Student)
        .filter(
            Student.user_id == current_user.id
        )
        .first()
    )

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found",
        )

    session_id = (
        payload.session_id
        or f"voice-{uuid4().hex}"
    )

    try:
        context = build_student_context(
            student=student,
            db=db,
        )

        knowledge_context = search_knowledge(
            query=payload.transcript,
            db=db,
            limit=3,
        )

        system_prompt = build_ai_system_prompt(
            student_context={},
            knowledge_context=knowledge_context,
        )
        response_language = resolve_language(payload.language, payload.transcript)
        system_prompt += (
            f"\n\nRESPONSE LANGUAGE: Reply in {language_label(response_language)}."
        )

        answer, answer_source = answer_student_question(
            payload.transcript,
            context,
            knowledge_context,
        )
        if answer is None:
            answer, _, _ = answer_general_question(
                payload.transcript,
                response_language,
            )
            if answer is None:
                service = GeminiService()
                answer = await service.generate(
                    system_instruction=system_prompt,
                    user_message=payload.transcript,
                )
                model_name = service.model
                answer_source = "voice_external_provider"
            else:
                model_name = "unisphere-general"
                answer_source = "general_information"
        else:
            answer = localize_grounded_answer(answer, response_language)
            model_name = "unisphere-grounded"

        interaction = AIInteractionV2(
            user_id=current_user.id,
            student_id=student.id,
            session_id=session_id,
            user_message=payload.transcript,
            ai_response=answer,
            model_name=model_name,
            context_type=answer_source,
            status="completed",
        )

        db.add(interaction)
        db.commit()
        db.refresh(interaction)

        return VoiceChatResponseV2(
            answer=answer,
            session_id=session_id,
            language=payload.language,
            interaction_id=interaction.id,
        )

    except Exception:
        logger.exception("Voice AI request failed")
        db.rollback()

        response_language = resolve_language(payload.language, payload.transcript)
        answer = (
            "मैं आपके छात्र रिकॉर्ड से इसकी पुष्टि नहीं कर सका। किसी विशेष UniSphere "
            "अनुभाग के बारे में पूछें या आधिकारिक सहायता के लिए हेल्पडेस्क का उपयोग करें।"
            if response_language == "hi"
            else "I could not verify that from your student record. Ask about a "
            "specific UniSphere section or use Helpdesk for official assistance."
        )

        interaction = AIInteractionV2(
            user_id=current_user.id,
            student_id=student.id,
            session_id=session_id,
            user_message=payload.transcript,
            ai_response=answer,
            model_name="unisphere-safe-fallback",
            context_type="voice_safe_fallback",
            status="completed_with_fallback",
        )

        db.add(interaction)
        db.commit()

        db.refresh(interaction)
        return VoiceChatResponseV2(
            answer=answer,
            session_id=session_id,
            language=payload.language,
            interaction_id=interaction.id,
        )
