from sqlalchemy import Column, String, Integer, Numeric, ForeignKey, Date, Uuid
from sqlalchemy.orm import relationship

from database.database import Base
from models.base_mixin import UUIDMixin, TimestampMixin

class MaintenanceLog(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "maintenance_logs"

    vehicle_id = Column(Uuid(as_uuid=True), ForeignKey("vehicles.id"), nullable=False)
    type = Column(String, nullable=False)   # oil_change, tire_rotation, etc.
    cost = Column(Numeric, nullable=True)
    odometer = Column(Integer, nullable=True)
    notes = Column(String, nullable=True)
    performed_at = Column(Date, nullable=False)

    vehicle = relationship("Vehicle", back_populates="maintenance_logs")
