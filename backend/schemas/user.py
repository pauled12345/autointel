from pydantic import BaseModel, EmailStr
from uuid import UUID
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    display_name: str | None = None

class UserCreate(UserBase):
    firebase_uid: str

class UserOut(UserBase):
    id: UUID
    created_at: datetime

    class Config:
        from_attributes = True
