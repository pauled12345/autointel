import json

from ai.llm_client import get_llm_client
from prompts.diagnostic_prompt import DIAGNOSTIC_SYSTEM_PROMPT, build_diagnostic_prompt
from prompts.chat_prompt import CHAT_SYSTEM_PROMPT
from utils.config import settings

_OFFLINE_SEVERITY = {
    "P0133": "medium",
    "P0301": "high",
    "P0420": "medium",
    "P0171": "medium",
}

_DIAGNOSIS_FIELDS = (
    "plain_explanation",
    "likely_causes",
    "symptoms",
    "severity",
    "recommended_action",
    "repair_difficulty",
    "estimated_cost",
)


def explain_fault_code(code: str, raw_description: str | None = None, live_pids: dict | None = None) -> dict:
    """Calls the configured LLM to translate a raw OBD-II fault code into a
    detailed plain-English diagnosis. Returns a dict with the full diagnosis
    schema (explanation, causes, symptoms, severity, action, difficulty, cost),
    ready to be cached in the database.

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
        cleaned = raw_response.strip().strip("`")
        if cleaned.startswith("json"):
            cleaned = cleaned[4:]
        parsed = json.loads(cleaned)

    return _normalize(parsed)


def _normalize(diagnosis: dict) -> dict:
    """Ensures every diagnosis field is present with a sensible default, so
    callers (and the mobile app) can rely on a stable shape even if the model
    omits a field."""
    result = dict(diagnosis)
    result["plain_explanation"] = str(result.get("plain_explanation") or "").strip()
    result["likely_causes"] = _as_list(result.get("likely_causes"))
    result["symptoms"] = _as_list(result.get("symptoms"))
    result["severity"] = (result.get("severity") or "medium").strip().lower()
    result["recommended_action"] = str(result.get("recommended_action") or "").strip()
    result["repair_difficulty"] = str(result.get("repair_difficulty") or "medium").strip()
    result["estimated_cost"] = str(result.get("estimated_cost") or "Varies — needs diagnosis").strip()
    return result


def _as_list(value) -> list:
    if isinstance(value, list):
        return [str(x).strip() for x in value if str(x).strip()]
    if isinstance(value, str) and value.strip():
        return [x.strip() for x in value.split(",") if x.strip()]
    return []


def _llm_unavailable() -> bool:
    if settings.llm_provider == "gemini":
        return not settings.gemini_api_key or settings.gemini_api_key == "your_gemini_key_here"
    return not settings.openai_api_key or settings.openai_api_key == "your_openai_key_here"


def chat(messages: list[dict]) -> str:
    """Chats with the configured LLM using the given conversation history
    (list of {role: user/assistant, content}). Returns the assistant's reply."""
    if _llm_unavailable():
        return "I'm offline right now — connect the backend to an AI provider to chat."
    client = get_llm_client()
    return client.chat(messages, CHAT_SYSTEM_PROMPT)


def _offline_explanation(code: str) -> dict:
    upper = code.upper()
    return {
        "plain_explanation": (
            f"Fault code {upper} was recorded by the vehicle's on-board diagnostics. "
            "The app is currently running offline, so a full explanation is not available "
            "yet — connect the backend to an LLM API key to receive a detailed diagnosis "
            "with likely causes, symptoms, and a recommended course of action."
        ),
        "likely_causes": [],
        "symptoms": [],
        "severity": _OFFLINE_SEVERITY.get(upper, "medium"),
        "recommended_action": "Have the vehicle inspected by a qualified technician.",
        "repair_difficulty": "medium",
        "estimated_cost": "Varies — needs diagnosis",
    }
