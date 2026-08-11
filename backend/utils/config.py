from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    firebase_credentials_path: str = "./firebase-service-account.json"
    llm_provider: str = "openai"  # "openai" or "gemini"
    openai_api_key: str = ""
    gemini_api_key: str = ""
    environment: str = "development"

    class Config:
        env_file = ".env"

settings = Settings()
