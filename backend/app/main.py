

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

from app.models.database import init_db
from app.routers import auth, files
from app.services.scheduler import start_scheduler, stop_scheduler

app = FastAPI(
    title="SecureFileShare API",
    description="Privacy-first file sharing with AES-256 encryption and RAM-only storage",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(files.router)


@app.on_event("startup")
def startup():
    init_db()
    start_scheduler()
    print("SecureFileShare backend started!")


@app.on_event("shutdown")
def shutdown():
    stop_scheduler()


@app.get("/")
def root():
    return {"message": "SecureFileShare API is running", "docs": "/docs"}