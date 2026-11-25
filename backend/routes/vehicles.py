from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from database.database import get_db
from services.auth_service import get_current_user
from models.user import User
from models.vehicle import Vehicle
from schemas.vehicle import VehicleCreate, VehicleOut

router = APIRouter(prefix="/vehicles", tags=["vehicles"])


@router.post("/", response_model=VehicleOut)
def create_vehicle(payload: VehicleCreate, db: Session = Depends(get_db),
                   user: User = Depends(get_current_user)):
    vehicle = Vehicle(user_id=user.id, **payload.model_dump())
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


@router.get("/", response_model=list[VehicleOut])
def list_vehicles(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return db.query(Vehicle).filter(Vehicle.user_id == user.id).all()


@router.get("/{vehicle_id}", response_model=VehicleOut)
def get_vehicle(vehicle_id: UUID, db: Session = Depends(get_db),
                user: User = Depends(get_current_user)):
    vehicle = (
        db.query(Vehicle)
        .filter(Vehicle.id == vehicle_id, Vehicle.user_id == user.id)
        .first()
    )
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle
