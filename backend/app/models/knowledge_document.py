from sqlalchemy import Column, Integer, String, Text

from app.core.database import Base


class KnowledgeDocument(Base):
    __tablename__ = "knowledge_documents"

    id = Column(Integer, primary_key=True, index=True)

    title = Column(
        String(250),
        nullable=False,
    )

    category = Column(
        String(100),
        nullable=False,
        index=True,
    )

    content = Column(
        Text,
        nullable=False,
    )

    source = Column(
        String(500),
        nullable=True,
    )

    is_active = Column(
        Integer,
        nullable=False,
        default=1,
    )
