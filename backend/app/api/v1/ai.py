from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.knowledge_document import KnowledgeDocument
from app.models.student import Student
from app.models.user import User
from app.schemas.ai import (
    AIChatRequest,
    AIChatResponse,
    KnowledgeSearchRequest,
    KnowledgeSearchResult,
    KnowledgeDocumentCreateRequest,
    KnowledgeDocumentResponse,
)
from app.services.ai_service import (
    generate_ai_response,
)
from app.services.rag_service import (
    search_knowledge,
)


router = APIRouter(
    prefix="/ai",
    tags=["AI Assistant"],
)


@router.post(
    "/chat",
    response_model=AIChatResponse,
)
def ai_chat(
    request: AIChatRequest,
    current_user: User = Depends(
        get_current_user
    ),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(
            Student.user_id == current_user.id
        )
        .first()
    )

    if student is None:
        return AIChatResponse(
            response=(
                "UniSphere AI is currently "
                "available for student accounts."
            ),
            intent="unsupported_role",
            source="unisphere_ai",
            knowledge_sources=[],
        )

    (
        response,
        intent,
        source,
        knowledge_sources,
    ) = generate_ai_response(
        message=request.message,
        student=student,
        db=db,
    )

    return AIChatResponse(
        response=response,
        intent=intent,
        source=source,
        knowledge_sources=knowledge_sources,
    )


@router.post(
    "/knowledge/search",
    response_model=list[KnowledgeSearchResult],
)
def knowledge_search(
    request: KnowledgeSearchRequest,
    current_user: User = Depends(
        get_current_user
    ),
    db: Session = Depends(get_db),
):
    results = search_knowledge(
        query=request.query,
        db=db,
        limit=5,
    )

    return results


@router.get(
    "/knowledge",
    response_model=list[KnowledgeDocumentResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_knowledge_documents(db: Session = Depends(get_db)):
    return (
        db.query(KnowledgeDocument)
        .order_by(KnowledgeDocument.category, KnowledgeDocument.title)
        .all()
    )


@router.post(
    "/knowledge",
    response_model=KnowledgeDocumentResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_role("admin"))],
)
def create_knowledge_document(
    request: KnowledgeDocumentCreateRequest,
    db: Session = Depends(get_db),
):
    document = KnowledgeDocument(
        title=request.title.strip(),
        category=request.category.strip(),
        content=request.content.strip(),
        source=request.source.strip() if request.source else None,
        is_active=1,
    )
    db.add(document)
    db.commit()
    db.refresh(document)
    return document


@router.patch(
    "/knowledge/{document_id}/deactivate",
    response_model=KnowledgeDocumentResponse,
    dependencies=[Depends(require_role("admin"))],
)
def deactivate_knowledge_document(
    document_id: int,
    db: Session = Depends(get_db),
):
    document = (
        db.query(KnowledgeDocument)
        .filter(KnowledgeDocument.id == document_id)
        .first()
    )
    if document is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Knowledge document not found",
        )
    document.is_active = 0
    db.commit()
    db.refresh(document)
    return document
