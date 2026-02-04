import os
import uuid
from typing import List, Optional

from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from database import engine, get_db
from models import Base, User, Delivery
from schemas import (
    LoginRequest, TokenResponse, MeResponse,
    CourierCreate, CompaniesUpdate, CourierOut,
    DeliveryOut, ApproveRequest
)
from auth import (
    hash_password, verify_password, create_access_token,
    require_admin, require_courier, get_current_user
)
from constants import VALID_COMPANIES, VALID_STATUSES

# ---- APP
app = FastAPI()

# CORS (para Flutter Web / testes)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # em produção: colocar domínio certinho
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# uploads
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# cria tabelas (DEV)
Base.metadata.create_all(bind=engine)

# ---- HELPERS
def delivery_to_out(d: Delivery) -> DeliveryOut:
    return DeliveryOut(
        id=d.id,
        user_id=d.user_id,
        created_at=d.created_at.isoformat(),
        photo_url=d.photo_url,
        status=d.status,
        company=d.company,
    )

# ---- AUTH
@app.post("/auth/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == payload.username).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Usuário ou senha inválidos")

    token = create_access_token(user)

    return TokenResponse(
        access_token=token,
        role=user.role,
        user_id=user.id,
        name=user.name,
        companies=user.get_companies() if user.role == "courier" else [],
    )

@app.get("/auth/me", response_model=MeResponse)
def me(user: User = Depends(get_current_user)):
    return MeResponse(
        id=user.id,
        name=user.name,
        username=user.username,
        role=user.role,
        companies=user.get_companies() if user.role == "courier" else [],
    )

# ---- COURIERS (ADMIN)
@app.get("/couriers", response_model=List[CourierOut])
def list_couriers(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    users = db.query(User).filter(User.role == "courier").all()
    return [
        CourierOut(
            id=u.id,
            name=u.name,
            username=u.username,
            companies=u.get_companies(),
        )
        for u in users
    ]

@app.post("/couriers", response_model=CourierOut)
def create_courier(payload: CourierCreate, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    companies = [c.strip().upper() for c in payload.companies]
    if any(c not in VALID_COMPANIES for c in companies):
        raise HTTPException(400, detail="Empresa inválida")

    exists = db.query(User).filter(User.username == payload.username).first()
    if exists:
        raise HTTPException(400, detail="Username já existe")

    courier = User(
        name=payload.name.strip(),
        username=payload.username.strip(),
        role="courier",
        password_hash=hash_password(payload.password),
    )
    courier.set_companies(companies)

    db.add(courier)
    db.commit()
    db.refresh(courier)

    return CourierOut(
        id=courier.id,
        name=courier.name,
        username=courier.username,
        companies=courier.get_companies(),
    )

@app.put("/couriers/{courier_id}/companies")
def update_companies(courier_id: int, payload: CompaniesUpdate, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    courier = db.query(User).filter(User.id == courier_id, User.role == "courier").first()
    if not courier:
        raise HTTPException(404, detail="Entregador não encontrado")

    companies = [c.strip().upper() for c in payload.companies]
    if any(c not in VALID_COMPANIES for c in companies):
        raise HTTPException(400, detail="Empresa inválida")

    courier.set_companies(companies)
    db.commit()
    return {"ok": True}

# ---- DELIVERIES (COURIER)
@app.post("/deliveries/upload")
def upload_delivery(
    company: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    courier: User = Depends(require_courier),
):
    company = company.strip().upper()
    if company not in VALID_COMPANIES:
        raise HTTPException(400, detail="Empresa inválida")

    if company not in courier.get_companies():
        raise HTTPException(403, detail="Você não faz entregas dessa empresa")

    ext = os.path.splitext(file.filename or "")[1].lower()
    safe_name = f"{uuid.uuid4().hex}{ext or '.jpg'}"
    path = os.path.join(UPLOAD_DIR, safe_name)

    content = file.file.read()
    with open(path, "wb") as f:
        f.write(content)

    d = Delivery(
        user_id=courier.id,
        company=company,
        status="pending",
        photo_url=f"/uploads/{safe_name}",
    )
    db.add(d)
    db.commit()
    db.refresh(d)

    return {"ok": True, "delivery_id": d.id, "photo_url": d.photo_url}

@app.get("/deliveries/me", response_model=List[DeliveryOut])
def my_deliveries(
    status: Optional[str] = None,
    company: Optional[str] = None,
    db: Session = Depends(get_db),
    courier: User = Depends(require_courier),
):
    q = db.query(Delivery).filter(Delivery.user_id == courier.id)

    if status:
        if status not in VALID_STATUSES:
            raise HTTPException(400, detail="Status inválido")
        q = q.filter(Delivery.status == status)

    if company:
        company = company.upper()
        q = q.filter(Delivery.company == company)

    q = q.order_by(Delivery.created_at.desc())
    return [delivery_to_out(d) for d in q.all()]

# ---- DELIVERIES (ADMIN)
@app.get("/deliveries/by-courier/{courier_id}", response_model=List[DeliveryOut])
def deliveries_by_courier(
    courier_id: int,
    status: Optional[str] = None,
    company: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    q = db.query(Delivery).filter(Delivery.user_id == courier_id)

    if status:
        if status not in VALID_STATUSES:
            raise HTTPException(400, detail="Status inválido")
        q = q.filter(Delivery.status == status)

    if company:
        company = company.upper()
        q = q.filter(Delivery.company == company)

    q = q.order_by(Delivery.created_at.desc())
    return [delivery_to_out(d) for d in q.all()]

@app.post("/deliveries/{delivery_id}/approve")
def approve_delivery(
    delivery_id: int,
    payload: ApproveRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    if payload.status not in ["approved", "rejected"]:
        raise HTTPException(400, detail="Status inválido")

    d = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not d:
        raise HTTPException(404, detail="Entrega não encontrada")

    d.status = payload.status
    db.commit()
    return {"ok": True}