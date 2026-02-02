import os
from datetime import datetime, timedelta
from typing import Optional, List

from fastapi import FastAPI, Depends, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from db import engine, Base, get_db
from models import User, Delivery
from schemas import (
    LoginRequest, LoginResponse,
    DeliveryCreateResponse, DeliveryItem,
    ApproveRequest, CreateCourierRequest, UserPublic
)
from auth import (
    verify_password,
    create_access_token,
    get_current_user,
    require_admin,
    hash_password,
)

Base.metadata.create_all(bind=engine)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

app = FastAPI(title="Entregas API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # ok pra dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/auth/login", response_model=LoginResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == body.username).first()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Usuário ou senha inválidos")

    token = create_access_token(user_id=user.id, role=user.role)
    return LoginResponse(access_token=token, role=user.role, name=user.name)


# ✅ ADMIN: listar entregadores (pra você escolher / ver quem existe)
@app.get("/users/couriers", response_model=List[UserPublic])
def list_couriers(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    couriers = db.query(User).filter(User.role == "courier").order_by(User.name.asc()).all()
    return couriers


# ✅ ADMIN: criar entregador
@app.post("/users/couriers", response_model=UserPublic)
def create_courier(
    body: CreateCourierRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    username = body.username.strip()
    name = body.name.strip()

    if len(username) < 3:
        raise HTTPException(status_code=400, detail="username muito curto")
    if len(body.password) < 6:
        raise HTTPException(status_code=400, detail="senha deve ter pelo menos 6 caracteres")

    exists = db.query(User).filter(User.username == username).first()
    if exists:
        raise HTTPException(status_code=409, detail="username já existe")

    user = User(
        name=name,
        username=username,
        password_hash=hash_password(body.password),
        role="courier",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@app.post("/deliveries", response_model=DeliveryCreateResponse)
def create_delivery(
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    ext = os.path.splitext(photo.filename)[1].lower()
    if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        raise HTTPException(status_code=400, detail="Formato inválido. Use jpg, png ou webp.")

    filename = f"{user.id}_{int(datetime.utcnow().timestamp())}{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as f:
        f.write(photo.file.read())

    photo_url = f"/uploads/{filename}"

    delivery = Delivery(
        user_id=user.id,
        created_at=datetime.utcnow(),
        photo_url=photo_url,
        status="pending",
        notes=None,
    )
    db.add(delivery)
    db.commit()
    db.refresh(delivery)
    return delivery


@app.get("/deliveries", response_model=List[DeliveryItem])
def list_deliveries(
    from_date: Optional[str] = None,   # "YYYY-MM-DD"
    to_date: Optional[str] = None,     # "YYYY-MM-DD"
    courier_id: Optional[int] = None,  # admin pode filtrar por entregador
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    q = db.query(Delivery).join(User)

    if user.role != "admin":
        q = q.filter(Delivery.user_id == user.id)
    else:
        if courier_id is not None:
            q = q.filter(Delivery.user_id == courier_id)

    def parse_date(d: str) -> datetime:
        return datetime.strptime(d, "%Y-%m-%d")

    if from_date:
        q = q.filter(Delivery.created_at >= parse_date(from_date))
    if to_date:
        q = q.filter(Delivery.created_at < parse_date(to_date) + timedelta(days=1))

    q = q.order_by(Delivery.created_at.desc())
    deliveries = q.all()

    for d in deliveries:
        _ = d.user

    return deliveries


@app.patch("/deliveries/{delivery_id}/status", response_model=DeliveryCreateResponse)
def set_delivery_status(
    delivery_id: int,
    body: ApproveRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    if body.status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="status deve ser approved ou rejected")

    delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not delivery:
        raise HTTPException(status_code=404, detail="Entrega não encontrada")

    delivery.status = body.status
    delivery.notes = body.notes
    db.commit()
    db.refresh(delivery)
    return delivery


@app.get("/stats/fortnight")
def stats_fortnight(
    start: str,  # "YYYY-MM-DD"
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    start_dt = datetime.strptime(start, "%Y-%m-%d")
    end_dt = start_dt + timedelta(days=14, hours=23, minutes=59, seconds=59)

    q = db.query(Delivery).filter(Delivery.created_at >= start_dt, Delivery.created_at <= end_dt)

    if user.role != "admin":
        q = q.filter(Delivery.user_id == user.id)

    deliveries = q.all()
    total = len(deliveries)

    by_day = {}
    for d in deliveries:
        key = d.created_at.strftime("%Y-%m-%d")
        by_day[key] = by_day.get(key, 0) + 1

    return {"start": start, "end": end_dt.strftime("%Y-%m-%d"), "total": total, "by_day": by_day}