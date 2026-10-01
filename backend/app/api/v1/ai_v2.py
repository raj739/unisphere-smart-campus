import logging
from uuid import uuid4

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.ai_interaction_v2 import AIInteractionV2
from app.models.student import Student
from app.schemas.ai_v2 import AIChatRequestV2, AIChatResponseV2, AIContextResponse
from app.services.ai_context_service import build_student_context
from app.services.ai_prompt_service import build_system_prompt
from app.services.gemini_service import GeminiService
from app.services.ai_language_service import (
    language_label,
    localize_grounded_answer,
    resolve_language,
)
from app.services.general_information_service import answer_general_question
from app.services.grounded_assistant_service import answer_student_question
from app.services.rag_service import search_knowledge


router = APIRouter(prefix="/ai-v2", tags=["UniSphere AI V2"])
logger = logging.getLogger(__name__)


def get_student_for_user(db: Session, user_id: int):
    return db.query(Student).filter(Student.user_id == user_id).first()


def context_response(student_context: dict) -> AIContextResponse:
    return AIContextResponse(
        uni_id=student_context.get("uni_id"),
        student_name=student_context.get("student_name"),
        programme=student_context.get("programme"),
        semester=student_context.get("semester"),
        attendance_percentage=student_context.get("attendance_percentage"),
        outstanding_fee=student_context.get("outstanding_fee"),
        academic_status=student_context.get("academic_status"),
    )


def complete_interaction(
    interaction: AIInteractionV2,
    answer: str,
    model: str,
    source: str,
    db: Session,
    status: str = "completed",
):
    interaction.ai_response = answer
    interaction.model_name = model
    interaction.context_type = source
    interaction.status = status
    db.commit()
    db.refresh(interaction)


def follow_up_suggestions(message: str, language: str) -> list[str]:
    normalized = message.lower()
    if language == "hi":
        if "attendance" in normalized or "उपस्थिति" in normalized:
            return ["कम उपस्थिति वाले विषय दिखाएं", "मेरी समय-सारणी दिखाएं", "सुधार के सुझाव दें"]
        if "fee" in normalized or "फीस" in normalized:
            return ["मेरे बिल दिखाएं", "मेरे हेल्पडेस्क टिकट दिखाएं", "मेरे प्रमाणपत्र दिखाएं"]
        return ["आज की समय-सारणी दिखाएं", "मेरी फीस बताएं", "मेरे सहायता मामले दिखाएं"]
    if "attendance" in normalized:
        return ["Which subjects are below 75%?", "Show today's timetable", "How can I improve?"]
    if "fee" in normalized:
        return ["Show my invoices", "Show my helpdesk tickets", "Show my certificates"]
    return ["Show today's timetable", "What fees are outstanding?", "Show my support cases"]


@router.post("/chat", response_model=AIChatResponseV2)
async def chat(
    request: AIChatRequestV2,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_for_user(db, current_user.id)
    student_context = build_student_context(db, student) if student else {}
    response_language = resolve_language(request.language, request.message)
    session_id = request.session_id or str(uuid4())
    knowledge_context = search_knowledge(query=request.message, db=db, limit=3)

    previous = (
        db.query(AIInteractionV2)
        .filter(
            AIInteractionV2.user_id == current_user.id,
            AIInteractionV2.session_id == session_id,
            AIInteractionV2.status.in_({"completed", "completed_with_fallback"}),
        )
        .order_by(AIInteractionV2.created_at.desc())
        .limit(6)
        .all()
    )
    conversation_context = [
        {"user": item.user_message, "assistant": item.ai_response}
        for item in reversed(previous)
    ]
    interaction = AIInteractionV2(
        user_id=current_user.id,
        student_id=student.id if student else None,
        session_id=session_id,
        user_message=request.message,
        status="processing",
    )
    db.add(interaction)
    db.commit()
    db.refresh(interaction)

    local_answer, local_source = answer_student_question(
        request.message,
        student_context,
        knowledge_context,
    )
    if local_answer is not None:
        local_answer = localize_grounded_answer(local_answer, response_language)
        suggestions = follow_up_suggestions(request.message, response_language)
        complete_interaction(
            interaction,
            local_answer,
            "unisphere-grounded",
            local_source,
            db,
        )
        return AIChatResponseV2(
            answer=local_answer,
            session_id=session_id,
            context=context_response(student_context),
            model="unisphere-grounded",
            interaction_id=interaction.id,
            source=local_source,
            detected_language=response_language,
            suggestions=suggestions,
        )

    general_answer, _, general_suggestions = answer_general_question(
        request.message,
        response_language,
    )
    if general_answer is not None:
        complete_interaction(
            interaction,
            general_answer,
            "unisphere-general",
            "general_information",
            db,
        )
        return AIChatResponseV2(
            answer=general_answer,
            session_id=session_id,
            context=context_response(student_context),
            model="unisphere-general",
            interaction_id=interaction.id,
            source="general_information",
            detected_language=response_language,
            suggestions=general_suggestions,
        )

    try:
        # External providers receive approved knowledge and conversation only.
        # Authenticated student records stay inside UniSphere.
        system_prompt = build_system_prompt(
            {},
            knowledge_context,
            conversation_context,
        )
        system_prompt += (
            "\n\nDo not claim access to personal student records."
            f"\nRESPONSE LANGUAGE: Reply in {language_label(response_language)}."
        )
        provider = GeminiService()
        answer = await provider.generate(
            system_instruction=system_prompt,
            user_message=request.message,
        )
        complete_interaction(
            interaction,
            answer,
            provider.model,
            "external_general",
            db,
        )
        return AIChatResponseV2(
            answer=answer,
            session_id=session_id,
            context=context_response(student_context),
            model=provider.model,
            interaction_id=interaction.id,
            source="external_provider",
            detected_language=response_language,
            suggestions=follow_up_suggestions(request.message, response_language),
        )
    except Exception:
        logger.exception("AI V2 provider request failed")
        answer = (
            "मैं आपके लाइव छात्र रिकॉर्ड या स्वीकृत कैंपस जानकारी से इस प्रश्न का "
            "सत्यापित उत्तर नहीं पा सका। किसी विशेष UniSphere अनुभाग के बारे में पूछें "
            "या आधिकारिक सहायता के लिए हेल्पडेस्क टिकट बनाएं।"
            if response_language == "hi"
            else "I could not verify an answer for that question from your live "
            "student record or approved campus guidance. Ask about a specific "
            "UniSphere section, or create a Helpdesk ticket for official assistance."
        )
        complete_interaction(
            interaction,
            answer,
            "unisphere-safe-fallback",
            "safe_fallback",
            db,
            status="completed_with_fallback",
        )
        return AIChatResponseV2(
            answer=answer,
            session_id=session_id,
            context=context_response(student_context),
            model="unisphere-safe-fallback",
            interaction_id=interaction.id,
            source="safe_fallback",
            detected_language=response_language,
            suggestions=follow_up_suggestions(request.message, response_language),
        )


@router.get("/history")
def history(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    interactions = (
        db.query(AIInteractionV2)
        .filter(AIInteractionV2.user_id == current_user.id)
        .order_by(AIInteractionV2.created_at.desc())
        .limit(50)
        .all()
    )
    return [
        {
            "id": item.id,
            "session_id": item.session_id,
            "message": item.user_message,
            "answer": item.ai_response,
            "model": item.model_name,
            "source": item.context_type,
            "status": item.status,
            "created_at": item.created_at,
        }
        for item in interactions
    ]
