from utils.config import settings

def get_llm_client():
    """Returns a thin wrapper exposing .explain() / .chat() regardless of which
    provider (OpenAI or Gemini) is configured."""
    if settings.llm_provider == "gemini":
        return _GeminiClient()
    return _OpenAIClient()


class _OpenAIClient:
    def __init__(self):
        from openai import OpenAI
        self.client = OpenAI(api_key=settings.openai_api_key)

    def explain(self, prompt: str, system_prompt: str) -> str:
        response = self.client.chat.completions.create(
            model=settings.openai_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
        )
        return response.choices[0].message.content

    def chat(self, messages: list[dict], system_prompt: str) -> str:
        response = self.client.chat.completions.create(
            model=settings.openai_model,
            messages=[{"role": "system", "content": system_prompt}, *messages],
            temperature=0.7,
        )
        return response.choices[0].message.content


class _GeminiClient:
    def __init__(self):
        import google.generativeai as genai
        genai.configure(api_key=settings.gemini_api_key)
        self.model = genai.GenerativeModel(
            "gemini-3.5-flash",
        )

    def explain(self, prompt: str, system_prompt: str) -> str:
        response = self.model.generate_content(f"{system_prompt}\n\n{prompt}")
        return response.text

    def chat(self, messages: list[dict], system_prompt: str) -> str:
        history = []
        first_user = True
        for m in messages:
            role = "model" if m["role"] == "assistant" else "user"
            content = m["content"]
            if role == "user" and first_user:
                content = f"{system_prompt}\n\n{content}"
                first_user = False
            history.append({"role": role, "parts": [content]})
        last = history.pop()
        return self.model.start_chat(history=history).send_message(last["parts"][0]).text
