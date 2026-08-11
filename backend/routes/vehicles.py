from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from database.database import get_db
from services.firebase_service import get_current_firebase_user
from models.vehicle import Vehicle
from models.user import User
from schemas.vehicle import VehicleCreate, VehicleOut

router = APIRouter(prefix="/vehicles", tags=["vehicles"])


def _get_or_create_user(db: Session, firebase_user: dict) -> User:
    user = db.query(User).filter(User.firebase_uid == firebase_user["uid"]).first()
    if not user:
        user = User(firebase_uid=firebase_user["uid"], email=firebase_user.get("email", ""))
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


@router.post("/", response_model=VehicleOut)
def create_vehicle(payload: VehicleCreate, db: Session = Depends(get_db),
                    firebase_user: dict = Depends(get_current_firebase_user)):
    user = _get_or_create_user(db, firebase_user)
    vehicle = Vehicle(user_id=user.id, **payload.model_dump())
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


@router.get("/", response_model=list[VehicleOut])
def list_vehicles(db: Session = Depends(get_db),
                   firebase_user: dict = Depends(get_current_firebase_user)):
    user = _get_or_create_user(db, firebase_user)
    return db.query(Vehicle).filter(Vehicle.user_id == user.id).all()


@router.get("/{vehicle_id}", response_model=VehicleOut)
def get_vehicle(vehicle_id: UUID, db: Session = Depends(get_db),
                 firebase_user: dict = Depends(get_current_firebase_user)):
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle
