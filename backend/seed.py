from database import engine, SessionLocal
from models import Base, User
from auth import hash_password

def run():
    # garante tabelas
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    # evita duplicar seed
    existing = db.query(User).filter(User.username == "admin").first()
    if existing:
        print("Seed já rodado (admin já existe).")
        db.close()
        return

    admin = User(
        name="Admin",
        username="admin",
        role="admin",
        password_hash=hash_password("admin123"),
    )

    courier1 = User(
        name="João",
        username="joao",
        role="courier",
        password_hash=hash_password("123"),
    )
    courier1.set_companies(["JET", "JADLOG"])

    courier2 = User(
        name="Maria",
        username="maria",
        role="courier",
        password_hash=hash_password("123"),
    )
    courier2.set_companies(["MERCADO_LIVRE"])

    db.add_all([admin, courier1, courier2])
    db.commit()
    db.close()

    print("Seed OK: admin/admin123, joao/123, maria/123")

if __name__ == "__main__":
    run()