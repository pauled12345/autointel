import json

from ai.llm_client import get_llm_client
from prompts.diagnostic_prompt import DIAGNOSTIC_SYSTEM_PROMPT, build_diagnostic_prompt


def explain_fault_code(code: str, raw_description: str | None = None, live_pids: dict | None = None) -> dict:
    """Calls the configured LLM to translate a raw OBD-II fault code into a
    plain-English explanation. Returns a dict matching the fault_codes.ai_explanation
    fields (explanation text + severity), ready to be cached in the database."""
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
