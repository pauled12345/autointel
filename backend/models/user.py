from sqlalchemy import Column, String
from sqlalchemy.orm import relationship

from database.database import Base
from models.base_mixin import UUIDMixin, TimestampMixin

class User(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "users"

    firebase_uid = Column(String, unique=True, nullable=False, index=True)
    email = Column(String, nullable=False)
    display_name = Column(String, nullable=True)

    vehicles = relationship("Vehicle", back_populates="owner", cascade="all, delete-orphan")
