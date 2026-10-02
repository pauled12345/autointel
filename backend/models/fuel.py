from sqlalchemy import Column, Numeric, ForeignKey, Date, Integer, Uuid
from sqlalchemy.orm import relationship

from database.database import Base
from models.base_mixin import UUIDMixin

class FuelLog(Base, UUIDMixin):
    __tablename__ = "fuel_logs"

    vehicle_id = Column(Uuid(as_uuid=True), ForeignKey("vehicles.id"), nullable=False)
    liters_or_gallons = Column(Numeric, nullable=False)
    cost = Column(Numeric, nullable=True)
    odometer = Column(Integer, nullable=True)
    recorded_at = Column(Date, nullable=False)

    vehicle = relationship("Vehicle", back_populates="fuel_logs")
