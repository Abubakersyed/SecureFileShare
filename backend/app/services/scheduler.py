from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
from app.models.database import SessionLocal, FileSession
from app.services import memory_store

scheduler = BackgroundScheduler()


def _cleanup_expired_files():
    db = SessionLocal()
    try:
        now = datetime.utcnow()
        expired = db.query(FileSession).filter(
            FileSession.expires_at <= now,
            FileSession.is_deleted == False
        ).all()

        for session in expired:
            memory_store.delete_file(session.session_id)
            session.is_deleted = True
            print(f"[TTL] Auto-deleted session {session.session_id}")

        db.commit()
    finally:
        db.close()


def start_scheduler():
    scheduler.add_job(_cleanup_expired_files, "interval", minutes=1)
    scheduler.start()
    print("[Scheduler] TTL cleanup job started")


def stop_scheduler():
    scheduler.shutdown()
    