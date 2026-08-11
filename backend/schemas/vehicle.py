from pydantic import BaseModel
from uuid import UUID
from datetime import datetime

class VehicleBase(BaseModel):
    make: str
    model: str
    year: int
    vin: str | None = None
    nickname: str | None = None

class VehicleCreate(VehicleBase):
    pass

class VehicleOut(VehicleBase):
    id: UUID
    user_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True
