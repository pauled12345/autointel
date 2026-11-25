from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "sqlite:///./autointel.db"
    firebase_credentials_path: str = "./firebase-service-account.json"
    llm_provider: str = "openai"  # "openai" or "gemini"
    openai_api_key: str = ""
    # Base or fine-tuned OpenAI model used for explanations. Point this at a
    # fine-tuned model id (e.g. "ft:gpt-4o-mini-...") to use it in production.
    openai_model: str = "gpt-4o-mini"
    gemini_api_key: str = ""
    # JWT signing secret for email/password auth. Override in production!
    jwt_secret: str = "dev-secret-change-me"
    jwt_expire_minutes: int = 60 * 24 * 30  # 30 days
    environment: str = "development"
    # When true, endpoints skip Firebase token verification and run as a local
    # "dev-user". Useful for local development without a Firebase project.
    auth_disabled: bool = False

    class Config:
        env_file = ".env"


settings = Settings()
