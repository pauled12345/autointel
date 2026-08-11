from pydantic import BaseModel
from uuid import UUID
from datetime import date

class FuelLogCreate(BaseModel):
    vehicle_id: UUID
    liters_or_gallons: float
    cost: float | None = None
    odometer: int | None = None
    recorded_at: date

class FuelLogOut(FuelLogCreate):
    id: UUID

    class Config:
        from_attributes = True
