from pydantic import BaseModel
from uuid import UUID
from datetime import datetime

class DiagnosticSessionCreate(BaseModel):
    vehicle_id: UUID

class DiagnosticSessionOut(BaseModel):
    id: UUID
    vehicle_id: UUID
    started_at: datetime
    ended_at: datetime | None = None

    class Config:
        from_attributes = True

class FaultCodeCreate(BaseModel):
    session_id: UUID
    code: str
    raw_description: str | None = None

class FaultCodeOut(BaseModel):
    id: UUID
    session_id: UUID
    code: str
    raw_description: str | None = None
    ai_explanation: str | None = None
    severity: str | None = None
    status: str

    class Config:
        from_attributes = True

class SensorReadingCreate(BaseModel):
    session_id: UUID
    pid: str
    value: float
    unit: str | None = None
    recorded_at: datetime
