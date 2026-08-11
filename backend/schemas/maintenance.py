from pydantic import BaseModel
from uuid import UUID
from datetime import date

class MaintenanceLogCreate(BaseModel):
    vehicle_id: UUID
    type: str
    cost: float | None = None
    odometer: int | None = None
    notes: str | None = None
    performed_at: date

class MaintenanceLogOut(MaintenanceLogCreate):
    id: UUID

    class Config:
        from_attributes = True
