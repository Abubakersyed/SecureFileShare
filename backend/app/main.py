from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.security import HTTPBearer
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

frontend_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "frontend")
if os.path.exists(frontend_path):
    app.mount("/static", StaticFiles(directory=frontend_path), name="static")


@app.get("/access/{session_id}", include_in_schema=False)
def serve_access_page(session_id: str):
    index_path = os.path.join(frontend_path, "index.html")
    return FileResponse(index_path)



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
    