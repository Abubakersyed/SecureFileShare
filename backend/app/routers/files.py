from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import Response
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import uuid
import os

from app.models.database import get_db, FileSession
from app.services.auth import get_current_user
from app.services.encryption import encrypt_file, decrypt_file
from app.services.memory_store import save_file, get_file, delete_file, file_exists
from app.services.qr_service import generate_qr_base64

router = APIRouter(prefix="/files", tags=["Files"])

MAX_FILE_SIZE_MB = int(os.getenv("MAX_FILE_SIZE_MB", 50))
ALLOWED_TTL = [5, 15, 30]


@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    ttl_minutes: int = Form(...),
    current_user: str = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if ttl_minutes not in ALLOWED_TTL:
        raise HTTPException(status_code=400, detail=f"TTL must be one of {ALLOWED_TTL} minutes")

    file_bytes = await file.read()
    size_mb = len(file_bytes) / (1024 * 1024)
    if size_mb > MAX_FILE_SIZE_MB:
        raise HTTPException(status_code=400, detail=f"File too large. Max size is {MAX_FILE_SIZE_MB}MB")

    encrypted_bytes = encrypt_file(file_bytes)
    session_id = str(uuid.uuid4())
    save_file(session_id, encrypted_bytes)

    expires_at = datetime.utcnow() + timedelta(minutes=ttl_minutes)
    session = FileSession(
        session_id=session_id,
        owner_email=current_user,
        original_filename=file.filename,
        file_size=len(file_bytes),
        ttl_minutes=ttl_minutes,
        expires_at=expires_at,
    )
    db.add(session)
    db.commit()

    qr_base64 = generate_qr_base64(session_id)

    return {
        "session_id": session_id,
        "filename": file.filename,
        "ttl_minutes": ttl_minutes,
        "expires_at": expires_at.isoformat(),
        "qr_code_base64": qr_base64,
        "access_url": f"/access/{session_id}"
    }


@router.get("/info/{session_id}")
def get_session_info(session_id: str, db: Session = Depends(get_db)):
    session = db.query(FileSession).filter(FileSession.session_id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.is_deleted:
        raise HTTPException(status_code=410, detail="File has been deleted")
    if datetime.utcnow() > session.expires_at:
        raise HTTPException(status_code=410, detail="Session has expired")

    return {
        "session_id": session_id,
        "filename": session.original_filename,
        "file_size": session.file_size,
        "expires_at": session.expires_at.isoformat() + "Z",
        "is_downloaded": session.is_downloaded,
        "ttl_minutes": session.ttl_minutes,
    }


@router.get("/download/{session_id}")
def download_file(session_id: str, db: Session = Depends(get_db)):
    session = db.query(FileSession).filter(FileSession.session_id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.is_deleted:
        raise HTTPException(status_code=410, detail="File has already been downloaded or deleted")
    if datetime.utcnow() > session.expires_at:
        raise HTTPException(status_code=410, detail="Session has expired")
    if not file_exists(session_id):
        raise HTTPException(status_code=404, detail="File no longer in memory")

    encrypted_bytes = get_file(session_id)
    decrypted_bytes = decrypt_file(encrypted_bytes)

    delete_file(session_id)
    session.is_downloaded = True
    session.is_deleted = True
    db.commit()

    return Response(
        content=decrypted_bytes,
        media_type="application/octet-stream",
        headers={
            "Content-Disposition": f'attachment; filename="{session.original_filename}"'
        }
    )


@router.delete("/cancel/{session_id}")
def cancel_session(
    session_id: str,
    current_user: str = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    session = db.query(FileSession).filter(FileSession.session_id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.owner_email != current_user:
        raise HTTPException(status_code=403, detail="You can only cancel your own sessions")
    if session.is_deleted:
        raise HTTPException(status_code=410, detail="Session already deleted")

    delete_file(session_id)
    session.is_deleted = True
    db.commit()

    return {"message": "Session cancelled and file deleted successfully"}

