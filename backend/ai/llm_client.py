from utils.config import settings

def get_llm_client():
    """Returns a thin wrapper exposing .explain(prompt, system_prompt) regardless of
    which provider (OpenAI or Gemini) is configured, so callers don't need provider-specific code."""
    if settings.llm_provider == "gemini":
        return _GeminiClient()
    return _OpenAIClient()


class _OpenAIClient:
    def __init__(self):
        from openai import OpenAI
        self.client = OpenAI(api_key=settings.openai_api_key)

    def explain(self, prompt: str, system_prompt: str) -> str:
        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
        )
        return response.choices[0].message.content


class _GeminiClient:
    def __init__(self):
        import google.generativeai as genai
        genai.configure(api_key=settings.gemini_api_key)
        self.model = genai.GenerativeModel(
            "gemini-1.5-flash",
        )

    def explain(self, prompt: str, system_prompt: str) -> str:
        response = self.model.generate_content(f"{system_prompt}\n\n{prompt}")
        return response.text
