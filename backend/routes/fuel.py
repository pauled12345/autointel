from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from uuid import UUID

from database.database import get_db
from services.firebase_service import get_current_firebase_user
from models.fuel import FuelLog
from schemas.fuel import FuelLogCreate, FuelLogOut

router = APIRouter(prefix="/fuel", tags=["fuel"])


@router.post("/", response_model=FuelLogOut)
def create_log(payload: FuelLogCreate, db: Session = Depends(get_db),
               firebase_user: dict = Depends(get_current_firebase_user)):
    log = FuelLog(**payload.model_dump())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


@router.get("/vehicle/{vehicle_id}", response_model=list[FuelLogOut])
def list_logs(vehicle_id: UUID, db: Session = Depends(get_db),
              firebase_user: dict = Depends(get_current_firebase_user)):
    return db.query(FuelLog).filter(FuelLog.vehicle_id == vehicle_id).all()
