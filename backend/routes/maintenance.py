from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from uuid import UUID

from database.database import get_db
from services.firebase_service import get_current_firebase_user
from models.maintenance import MaintenanceLog
from schemas.maintenance import MaintenanceLogCreate, MaintenanceLogOut

router = APIRouter(prefix="/maintenance", tags=["maintenance"])


@router.post("/", response_model=MaintenanceLogOut)
def create_log(payload: MaintenanceLogCreate, db: Session = Depends(get_db),
                firebase_user: dict = Depends(get_current_firebase_user)):
    log = MaintenanceLog(**payload.model_dump())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


@router.get("/vehicle/{vehicle_id}", response_model=list[MaintenanceLogOut])
def list_logs(vehicle_id: UUID, db: Session = Depends(get_db),
              firebase_user: dict = Depends(get_current_firebase_user)):
    return db.query(MaintenanceLog).filter(MaintenanceLog.vehicle_id == vehicle_id).all()
