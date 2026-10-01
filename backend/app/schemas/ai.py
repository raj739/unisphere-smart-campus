from pydantic import BaseModel, Field


class AIChatRequest(BaseModel):
    message: str = Field(
        min_length=1,
        max_length=2000,
    )


class AIChatResponse(BaseModel):
    response: str
    intent: str
    source: str
    knowledge_sources: list[str] = []


class KnowledgeSearchRequest(BaseModel):
    query: str = Field(
        min_length=1,
        max_length=1000,
    )


class KnowledgeSearchResult(BaseModel):
    title: str
    category: str
    content: str
    source: str | None
    score: float


class KnowledgeDocumentCreateRequest(BaseModel):
    title: str = Field(min_length=3, max_length=250)
    category: str = Field(min_length=2, max_length=100)
    content: str = Field(min_length=20, max_length=20000)
    source: str | None = Field(default=None, max_length=500)


class KnowledgeDocumentResponse(BaseModel):
    id: int
    title: str
    category: str
    content: str
    source: str | None
    is_active: int
