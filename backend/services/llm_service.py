import json

from ai.llm_client import get_llm_client
from prompts.diagnostic_prompt import DIAGNOSTIC_SYSTEM_PROMPT, build_diagnostic_prompt
from utils.config import settings

_OFFLINE_SEVERITY = {
    "P0133": "medium",
    "P0301": "high",
    "P0420": "medium",
    "P0171": "medium",
}


def explain_fault_code(code: str, raw_description: str | None = None, live_pids: dict | None = None) -> dict:
    """Calls the configured LLM to translate a raw OBD-II fault code into a
    plain-English explanation. Returns a dict matching the fault_codes.ai_explanation
    fields (explanation text + severity), ready to be cached in the database.

    Falls back to an offline placeholder when no LLM API key is configured, so
    the diagnostics flow still works end-to-end during local development."""
    if _llm_unavailable():
        return _offline_explanation(code)

    client = get_llm_client()
    prompt = build_diagnostic_prompt(code, raw_description, live_pids)
    raw_response = client.explain(prompt, DIAGNOSTIC_SYSTEM_PROMPT)

    try:
        parsed = json.loads(raw_response)
    except json.JSONDecodeError:
        # Fallback if the model wraps JSON in markdown fences or adds stray text
        cleaned = raw_response.strip().strip("`").replace("json\n", "")
        parsed = json.loads(cleaned)

    return parsed


def _llm_unavailable() -> bool:
    if settings.llm_provider == "gemini":
        return not settings.gemini_api_key or settings.gemini_api_key == "your_gemini_key_here"
    return not settings.openai_api_key or settings.openai_api_key == "your_openai_key_here"


def _offline_explanation(code: str) -> dict:
    upper = code.upper()
    return {
        "plain_explanation": (
            f"Fault code {upper} was detected by the vehicle's on-board diagnostics. "
            "This is an offline placeholder explanation — configure an LLM API key "
            "to receive a detailed, plain-English diagnosis."
        ),
        "severity": _OFFLINE_SEVERITY.get(upper, "medium"),
    }
