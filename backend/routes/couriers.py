from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from models import User
from schemas import CourierCreate, CompaniesUpdate
from auth import require_admin, hash_password
from database import get_db
from constants import VALID_COMPANIES

router = APIRouter(prefix="/couriers", tags=["Couriers"])

@router.post("")
def create_courier(
    payload: CourierCreate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    companies = [c.upper() for c in payload.companies]

    if any(c not in VALID_COMPANIES for c in companies):
        raise HTTPException(400, "Empresa inválida")

    courier = User(
        name=payload.name,
        username=payload.username,
        role="courier",
        password_hash=hash_password(payload.password),
    )
    courier.set_companies(companies)

    db.add(courier)
    db.commit()
    db.refresh(courier)

    return {
        "id": courier.id,
        "name": courier.name,
        "username": courier.username,
        "companies": courier.get_companies(),
    }


@router.put("/{courier_id}/companies")
def update_companies(
    courier_id: int,
    payload: CompaniesUpdate,
    db: Session = Depends(get_db),
    admin=Depends(require_admin),
):
    courier = db.query(User).filter(
        User.id == courier_id,
        User.role == "courier"
    ).first()

    if not courier:
        raise HTTPException(404, "Entregador não encontrado")

    companies = [c.upper() for c in payload.companies]
    if any(c not in VALID_COMPANIES for c in companies):
        raise HTTPException(400, "Empresa inválida")

    courier.set_companies(companies)
    db.commit()
    return {"ok": True}