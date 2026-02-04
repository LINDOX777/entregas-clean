import json
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    role = Column(String, nullable=False)  # "admin" | "courier"
    password_hash = Column(String, nullable=False)

    # JSON string: ["JET","JADLOG"]
    courier_companies = Column(Text, nullable=False, default="[]")

    deliveries = relationship("Delivery", back_populates="user")

    def get_companies(self):
        try:
            return json.loads(self.courier_companies or "[]")
        except Exception:
            return []

    def set_companies(self, companies: list[str]):
        self.courier_companies = json.dumps(companies)


class Delivery(Base):
    __tablename__ = "deliveries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    photo_url = Column(String, nullable=False)  # "/uploads/arquivo.jpg"
    status = Column(String, default="pending", nullable=False)  # pending/approved/rejected
    company = Column(String, nullable=False)  # JET/JADLOG/MERCADO_LIVRE

    user = relationship("User", back_populates="deliveries")