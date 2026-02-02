from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    name: str


class UserPublic(BaseModel):
    id: int
    name: str
    username: str
    role: str

    class Config:
        from_attributes = True


class CreateCourierRequest(BaseModel):
    name: str
    username: str
    password: str


class DeliveryCreateResponse(BaseModel):
    id: int
    created_at: datetime
    photo_url: str
    status: str
    notes: Optional[str] = None

    class Config:
        from_attributes = True


class DeliveryItem(BaseModel):
    id: int
    created_at: datetime
    photo_url: str
    status: str
    notes: Optional[str] = None
    user: UserPublic

    class Config:
        from_attributes = True


class ApproveRequest(BaseModel):
    status: str  # "approved" ou "rejected"
    notes: Optional[str] = None
