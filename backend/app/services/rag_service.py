import re

from sqlalchemy.orm import Session

from app.models.knowledge_document import KnowledgeDocument


STOP_WORDS = {
    "the",
    "is",
    "are",
    "what",
    "how",
    "when",
    "where",
    "can",
    "i",
    "my",
    "to",
    "of",
    "for",
    "and",
    "in",
    "a",
    "an",
    "do",
    "does",
    "please",
    "और",
    "है",
    "हैं",
    "का",
    "की",
    "के",
    "को",
    "में",
    "से",
    "क्या",
    "कैसे",
    "कब",
    "कहाँ",
    "मैं",
    "मेरा",
}


def tokenize(text: str) -> set[str]:
    # Unicode word matching keeps Hindi and English queries searchable.
    words = re.findall(r"[^\W_]+", text.lower(), flags=re.UNICODE)

    return {
        word
        for word in words
        if word not in STOP_WORDS
    }


def calculate_relevance(
    query: str,
    content: str,
    title: str,
) -> float:
    query_words = tokenize(query)

    if not query_words:
        return 0.0

    content_words = tokenize(content)
    title_words = tokenize(title)

    content_matches = query_words.intersection(
        content_words
    )

    title_matches = query_words.intersection(
        title_words
    )

    content_score = (
        len(content_matches)
        / len(query_words)
    )

    title_score = (
        len(title_matches)
        / len(query_words)
    )

    return (
        content_score * 0.7
        + title_score * 0.3
    )


def search_knowledge(
    query: str,
    db: Session,
    limit: int = 3,
) -> list[dict]:

    documents = (
        db.query(KnowledgeDocument)
        .filter(
            KnowledgeDocument.is_active == 1
        )
        .all()
    )

    scored_documents = []

    for document in documents:
        score = calculate_relevance(
            query=query,
            content=document.content,
            title=document.title,
        )

        if score > 0:
            scored_documents.append(
                {
                    "id": document.id,
                    "title": document.title,
                    "category": document.category,
                    "content": document.content,
                    "source": document.source,
                    "score": round(score, 4),
                }
            )

    scored_documents.sort(
        key=lambda item: item["score"],
        reverse=True,
    )

    return scored_documents[:limit]
