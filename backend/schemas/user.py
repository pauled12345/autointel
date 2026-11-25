from pydantic import BaseModel
from uuid import UUID
from datetime import datetime


class UserOut(BaseModel):
    id: UUID
    email: str
    display_name: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True
