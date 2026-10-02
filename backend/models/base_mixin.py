import uuid
from sqlalchemy import Column, DateTime, Uuid
from sqlalchemy.sql import func

class UUIDMixin:
    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)

class TimestampMixin:
    created_at = Column(DateTime(timezone=True), server_default=func.now())
