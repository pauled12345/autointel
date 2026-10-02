from sqlalchemy import Column, String, Integer, ForeignKey, Uuid
from sqlalchemy.orm import relationship

from database.database import Base
from models.base_mixin import UUIDMixin, TimestampMixin

class Vehicle(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "vehicles"

    user_id = Column(Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False)
    make = Column(String, nullable=False)
    model = Column(String, nullable=False)
    year = Column(Integer, nullable=False)
    vin = Column(String, nullable=True)
    nickname = Column(String, nullable=True)

    owner = relationship("User", back_populates="vehicles")
    diagnostic_sessions = relationship("DiagnosticSession", back_populates="vehicle", cascade="all, delete-orphan")
    maintenance_logs = relationship("MaintenanceLog", back_populates="vehicle", cascade="all, delete-orphan")
    fuel_logs = relationship("FuelLog", back_populates="vehicle", cascade="all, delete-orphan")
