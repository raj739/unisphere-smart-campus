import json
from pathlib import Path

from app.core.database import SessionLocal
from app.models.knowledge_document import KnowledgeDocument


BASE_DIR = Path(__file__).resolve().parents[2]

KNOWLEDGE_FILE = (
    BASE_DIR
    / "mock-data"
    / "knowledge"
    / "university_knowledge.json"
)


def seed_knowledge():
    with open(
        KNOWLEDGE_FILE,
        "r",
        encoding="utf-8-sig",
    ) as file:
        documents = json.load(file)

    db = SessionLocal()

    try:
        existing_titles = {
            title
            for (title,) in db.query(KnowledgeDocument.title).all()
        }
        added = 0
        for item in documents:
            if item["title"] in existing_titles:
                continue
            document = KnowledgeDocument(
                title=item["title"],
                category=item["category"],
                content=item["content"],
                source=item.get("source"),
                is_active=1,
            )

            db.add(document)
            added += 1

        db.commit()

        print(
            f"Added {added} knowledge documents."
        )

    finally:
        db.close()


if __name__ == "__main__":
    seed_knowledge()
