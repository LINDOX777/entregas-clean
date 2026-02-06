from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.types import TypeDecorator, VARCHAR
import json
from datetime import datetime
from db import Base


class JSONEncodedList(TypeDecorator):
    """Armazena lista como JSON string no SQLite"""
    impl = VARCHAR
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is not None:
            return json.dumps(value)
        return json.dumps([])

    def process_result_value(self, value, dialect):
        if value is not None:
            return json.loads(value)
        return []


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, nullable=False)  # "admin" ou "courier"
    companies = Column(JSONEncodedList, default=list, nullable=False)  # Lista de empresas: ["jet", "jadlog", "mercado_livre"]

    deliveries = relationship("Delivery", back_populates="user")


class Delivery(Base):
    __tablename__ = "deliveries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    photo_url = Column(String, nullable=False)
    company = Column(String, nullable=False, index=True)  # "jet", "jadlog", "mercado_livre"

    status = Column(String, default="pending", nullable=False)  # pending/approved/rejected
    notes = Column(String, nullable=True)  # motivo de reprovar, etc.

    user = relationship("User", back_populates="deliveries")