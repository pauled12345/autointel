from fastapi import APIRouter, Depends
from pydantic import BaseModel, field_validator

from database.database import get_db
from services.auth_service import get_current_user
from models.user import User
from services.llm_service import chat

router = APIRouter(prefix="/chat", tags=["chat"])


class ChatMessage(BaseModel):
    role: str  # "user" or "assistant"
    content: str

    @field_validator("role")
    @classmethod
    def _role(cls, v: str) -> str:
        if v not in ("user", "assistant"):
            raise ValueError("role must be 'user' or 'assistant'")
        return v


class ChatRequest(BaseModel):
    messages: list[ChatMessage]


class ChatResponse(BaseModel):
    reply: str


@router.post("/", response_model=ChatResponse)
def send_chat(payload: ChatRequest, db=Depends(get_db), user: User = Depends(get_current_user)):
    messages = [{"role": m.role, "content": m.content} for m in payload.messages]
    reply = chat(messages)
    return ChatResponse(reply=reply)
