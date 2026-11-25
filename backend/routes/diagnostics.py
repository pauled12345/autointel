import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from datetime import datetime, timezone

from database.database import get_db
from services.auth_service import get_current_user
from models.user import User
from models.vehicle import Vehicle
from models.diagnostic import DiagnosticSession, FaultCode, SensorReading
from schemas.diagnostic import (
    DiagnosticSessionCreate, DiagnosticSessionOut,
    FaultCodeCreate, FaultCodeOut, SensorReadingCreate,
)
from services.llm_service import explain_fault_code

router = APIRouter(prefix="/diagnostics", tags=["diagnostics"])


def _owned_vehicle(db: Session, user_id, vehicle_id: UUID) -> Vehicle:
    vehicle = (
        db.query(Vehicle)
        .filter(Vehicle.id == vehicle_id, Vehicle.user_id == user_id)
        .first()
    )
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle


def _owned_session(db: Session, user_id, session_id: UUID) -> DiagnosticSession:
    session = db.query(DiagnosticSession).filter(DiagnosticSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    _owned_vehicle(db, user_id, session.vehicle_id)
    return session


@router.post("/sessions", response_model=DiagnosticSessionOut)
def start_session(payload: DiagnosticSessionCreate, db: Session = Depends(get_db),
                  user: User = Depends(get_current_user)):
    _owned_vehicle(db, user.id, payload.vehicle_id)
    session = DiagnosticSession(vehicle_id=payload.vehicle_id, started_at=datetime.now(timezone.utc))
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.post("/sessions/{session_id}/end", response_model=DiagnosticSessionOut)
def end_session(session_id: UUID, db: Session = Depends(get_db),
                user: User = Depends(get_current_user)):
    session = _owned_session(db, user.id, session_id)
    session.ended_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(session)
    return session


@router.post("/fault-codes", response_model=FaultCodeOut)
def report_fault_code(payload: FaultCodeCreate, db: Session = Depends(get_db),
                      user: User = Depends(get_current_user)):
    """Stores a raw fault code read from the vehicle, then calls the LLM to
    generate and cache a detailed plain-English diagnosis."""
    _owned_session(db, user.id, payload.session_id)
    ai_result = explain_fault_code(payload.code, payload.raw_description)

    fault = FaultCode(
        session_id=payload.session_id,
        code=payload.code,
        raw_description=payload.raw_description,
        ai_explanation=json.dumps(ai_result),
        severity=ai_result.get("severity"),
        status="active",
    )
    db.add(fault)
    db.commit()
    db.refresh(fault)
    return fault


@router.get("/sessions/{session_id}/fault-codes", response_model=list[FaultCodeOut])
def list_fault_codes(session_id: UUID, db: Session = Depends(get_db),
                     user: User = Depends(get_current_user)):
    _owned_session(db, user.id, session_id)
    return db.query(FaultCode).filter(FaultCode.session_id == session_id).all()


@router.post("/sensor-readings")
def report_sensor_reading(payload: SensorReadingCreate, db: Session = Depends(get_db),
                          user: User = Depends(get_current_user)):
    _owned_session(db, user.id, payload.session_id)
    reading = SensorReading(**payload.model_dump())
    db.add(reading)
    db.commit()
    return {"status": "ok"}
