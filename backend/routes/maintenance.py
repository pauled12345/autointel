from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from database.database import get_db
from services.auth_service import get_current_user
from models.user import User
from models.vehicle import Vehicle
from models.maintenance import MaintenanceLog
from schemas.maintenance import MaintenanceLogCreate, MaintenanceLogOut

router = APIRouter(prefix="/maintenance", tags=["maintenance"])


def _owned_vehicle(db: Session, user_id, vehicle_id: UUID) -> Vehicle:
    vehicle = (
        db.query(Vehicle)
        .filter(Vehicle.id == vehicle_id, Vehicle.user_id == user_id)
        .first()
    )
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle


@router.post("/", response_model=MaintenanceLogOut)
def create_log(payload: MaintenanceLogCreate, db: Session = Depends(get_db),
               user: User = Depends(get_current_user)):
    _owned_vehicle(db, user.id, payload.vehicle_id)
    log = MaintenanceLog(**payload.model_dump())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


@router.get("/vehicle/{vehicle_id}", response_model=list[MaintenanceLogOut])
def list_logs(vehicle_id: UUID, db: Session = Depends(get_db),
              user: User = Depends(get_current_user)):
    _owned_vehicle(db, user.id, vehicle_id)
    return db.query(MaintenanceLog).filter(MaintenanceLog.vehicle_id == vehicle_id).all()
