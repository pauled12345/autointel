from sqlalchemy import Column, String, Numeric, ForeignKey, DateTime, Uuid
from sqlalchemy.orm import relationship

from database.database import Base
from models.base_mixin import UUIDMixin, TimestampMixin

class DiagnosticSession(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "diagnostic_sessions"

    vehicle_id = Column(Uuid(as_uuid=True), ForeignKey("vehicles.id"), nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=False)
    ended_at = Column(DateTime(timezone=True), nullable=True)

    vehicle = relationship("Vehicle", back_populates="diagnostic_sessions")
    fault_codes = relationship("FaultCode", back_populates="session", cascade="all, delete-orphan")
    sensor_readings = relationship("SensorReading", back_populates="session", cascade="all, delete-orphan")


class FaultCode(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "fault_codes"

    session_id = Column(Uuid(as_uuid=True), ForeignKey("diagnostic_sessions.id"), nullable=False)
    code = Column(String, nullable=False)             # e.g. "P0301"
    raw_description = Column(String, nullable=True)
    ai_explanation = Column(String, nullable=True)     # cached LLM output
    severity = Column(String, nullable=True)           # low/medium/high/critical
    status = Column(String, default="active")          # active/cleared

    session = relationship("DiagnosticSession", back_populates="fault_codes")


class SensorReading(Base, UUIDMixin):
    __tablename__ = "sensor_readings"

    session_id = Column(Uuid(as_uuid=True), ForeignKey("diagnostic_sessions.id"), nullable=False)
    pid = Column(String, nullable=False)     # e.g. "RPM", "COOLANT_TEMP"
    value = Column(Numeric, nullable=False)
    unit = Column(String, nullable=True)
    recorded_at = Column(DateTime(timezone=True), nullable=False)

    session = relationship("DiagnosticSession", back_populates="sensor_readings")
