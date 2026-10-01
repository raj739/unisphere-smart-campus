import asyncio
import os
from typing import Any

import httpx


class GeminiService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY", "").strip()
        self.model = os.getenv(
            "GEMINI_MODEL",
            "gemini-3.8-flash",
        ).strip()
        fallback_models = os.getenv(
            "GEMINI_FALLBACK_MODELS",
            "gemini-3.5-flash-lite,gemini-3.6-flash",
        )
        self.models = list(
            dict.fromkeys(
                [
                    self.model,
                    *(item.strip() for item in fallback_models.split(",")),
                ]
            )
        )
        self.models = [model for model in self.models if model]
        self.max_retries = max(
            0,
            int(os.getenv("GEMINI_MAX_RETRIES", "1")),
        )
        self.retry_base_seconds = max(
            0.1,
            float(os.getenv("GEMINI_RETRY_BASE_SECONDS", "1")),
        )

    async def generate(
        self,
        system_instruction: str,
        user_message: str,
    ) -> str:

        if not self.api_key:
            raise RuntimeError(
                "GEMINI_API_KEY is not configured"
            )

        payload = {
            "system_instruction": {
                "parts": [
                    {
                        "text": system_instruction
                    }
                ]
            },
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {
                            "text": user_message
                        }
                    ],
                }
            ],
        }

        headers = {
            "x-goog-api-key": self.api_key,
            "Content-Type": "application/json",
        }

        retryable_statuses = {429, 500, 502, 503, 504}
        last_error: RuntimeError | None = None

        async with httpx.AsyncClient(timeout=60) as client:
            for model in self.models:
                url = (
                    "https://generativelanguage.googleapis.com/"
                    f"v1beta/models/{model}:generateContent"
                )
                for attempt in range(self.max_retries + 1):
                    response = await client.post(
                        url,
                        json=payload,
                        headers=headers,
                    )

                    if response.status_code < 400:
                        data: dict[str, Any] = response.json()
                        candidates = data.get("candidates", [])
                        if not candidates:
                            raise RuntimeError("Gemini returned no candidates")

                        parts = (
                            candidates[0]
                            .get("content", {})
                            .get("parts", [])
                        )
                        answer = "".join(
                            part.get("text", "")
                            for part in parts
                        ).strip()
                        if not answer:
                            raise RuntimeError("Gemini returned an empty response")

                        self.model = model
                        return answer

                    last_error = RuntimeError(
                        f"Gemini model {model} failed with status "
                        f"{response.status_code}"
                    )
                    if response.status_code not in retryable_statuses:
                        raise last_error
                    if attempt < self.max_retries:
                        await asyncio.sleep(
                            self.retry_base_seconds * (2 ** attempt)
                        )

        raise last_error or RuntimeError("Gemini request failed")


async def _generate_gemini_response_async(
    message: str,
    context: str,
) -> str:

    service = GeminiService()

    system_instruction = """
You are UniSphere AI, an intelligent university assistant.

Use the verified context provided below when answering.

Rules:
- Do not invent university-specific information.
- Do not invent student data.
- Prefer verified student data and university knowledge.
- If information is unavailable, clearly say so.
- Never expose passwords, API keys, tokens, or internal secrets.
- Do not claim that an action was performed unless the system actually performed it.
- Give concise and useful answers.

VERIFIED CONTEXT:
""" + context

    return await service.generate(
        system_instruction=system_instruction,
        user_message=message,
    )


def generate_gemini_response(
    message: str,
    context: str,
) -> str:
    """
    Backward-compatible synchronous wrapper.

    The legacy AI service calls Gemini synchronously,
    while the new GeminiService uses async HTTP.
    """

    try:
        asyncio.get_running_loop()
    except RuntimeError:
        return asyncio.run(
            _generate_gemini_response_async(
                message=message,
                context=context,
            )
        )

    raise RuntimeError(
        "generate_gemini_response() cannot be called "
        "synchronously from an active async event loop."
    )
