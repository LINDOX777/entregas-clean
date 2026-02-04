from pydantic import BaseModel
from typing import List, Optional

class LoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: int
    name: str
    companies: List[str] = []

class MeResponse(BaseModel):
    id: int
    name: str
    username: str
    role: str
    companies: List[str] = []

class CourierCreate(BaseModel):
    name: str
    username: str
    password: str
    companies: List[str]

class CompaniesUpdate(BaseModel):
    companies: List[str]

class CourierOut(BaseModel):
    id: int
    name: str
    username: str
    companies: List[str]

class DeliveryOut(BaseModel):
    id: int
    user_id: int
    created_at: str
    photo_url: str
    status: str
    company: str

class ApproveRequest(BaseModel):
    status: str  # "approved" | "rejected"