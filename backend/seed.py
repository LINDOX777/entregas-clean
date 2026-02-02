from sqlalchemy.orm import Session
from db import SessionLocal, engine, Base
from models import User
from auth import hash_password

Base.metadata.create_all(bind=engine)

def run():
    db: Session = SessionLocal()

    # evita duplicar
    if db.query(User).count() > 0:
        print("Já tem usuários no banco. Seed ignorado.")
        return

    admin = User(
        name="Admin",
        username="admin",
        password_hash=hash_password("admin123"),
        role="admin",
    )

    courier = User(
        name="Entregador 1",
        username="entregador",
        password_hash=hash_password("123456"),
        role="courier",
    )

    db.add(admin)
    db.add(courier)
    db.commit()
    db.close()

    print("Seed OK. Login admin/admin123 e entregador/123456")

if __name__ == "__main__":
    run()