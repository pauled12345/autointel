from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "sqlite:///./autointel.db"
    firebase_credentials_path: str = "./firebase-service-account.json"
    llm_provider: str = "openai"  # "openai" or "gemini"
    openai_api_key: str = ""
    gemini_api_key: str = ""
    environment: str = "development"
    # When true, endpoints skip Firebase token verification and run as a local
    # "dev-user". Useful for local development without a Firebase project.
    auth_disabled: bool = False

    class Config:
        env_file = ".env"


settings = Settings()
