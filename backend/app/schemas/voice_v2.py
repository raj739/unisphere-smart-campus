from pydantic import BaseModel, Field


class VoiceChatRequestV2(BaseModel):
    transcript: str = Field(
        min_length=1,
        max_length=5000,
    )

    session_id: str | None = Field(
        default=None,
        max_length=150,
    )

    language: str = Field(
        default="en-IN",
        max_length=20,
    )


class VoiceChatResponseV2(BaseModel):
    answer: str
    session_id: str
    language: str
    interaction_id: int
