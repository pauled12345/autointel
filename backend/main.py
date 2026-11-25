from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from database.database import Base, engine
from routes import auth, vehicles, diagnostics, maintenance, fuel, chat
import models  # noqa: F401 ensures all models are registered with Base

app = FastAPI(title="AutoIntel API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten before production
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    # For local dev only — use Alembic migrations in place of this for production.
    Base.metadata.create_all(bind=engine)


app.include_router(auth.router)
app.include_router(vehicles.router)
app.include_router(diagnostics.router)
app.include_router(maintenance.router)
app.include_router(fuel.router)
app.include_router(chat.router)


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.get("/health/db")
def health_db():
    """Touches the database so Neon doesn't auto-suspend (used by keep-alive)."""
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    return {"status": "ok", "db": "ok"}
