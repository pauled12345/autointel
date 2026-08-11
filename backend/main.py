from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database.database import Base, engine
from services.firebase_service import init_firebase
from routes import vehicles, diagnostics, maintenance, fuel
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
    init_firebase()
    # For local dev only — use Alembic migrations in place of this for production.
    Base.metadata.create_all(bind=engine)


app.include_router(vehicles.router)
app.include_router(diagnostics.router)
app.include_router(maintenance.router)
app.include_router(fuel.router)


@app.get("/health")
def health_check():
    return {"status": "ok"}
