from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from models import Delivery, User
from database import get_db
from auth import require_courier
from constants import VALID_COMPANIES
import uuid, os

router = APIRouter(prefix="/deliveries", tags=["Deliveries"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload")
def upload_delivery(
    company: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(require_courier),
):
    company = company.upper()

    if company not in VALID_COMPANIES:
        raise HTTPException(400, "Empresa inválida")

    if company not in user.get_companies():
        raise HTTPException(403, "Você não faz entregas dessa empresa")

    filename = f"{uuid.uuid4()}_{file.filename}"
    path = os.path.join(UPLOAD_DIR, filename)

    with open(path, "wb") as f:
        f.write(file.file.read())

    delivery = Delivery(
        user_id=user.id,
        photo_url=path,
        company=company,
    )

    db.add(delivery)
    db.commit()

    return {"ok": True}