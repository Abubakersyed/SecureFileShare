import threading

_store: dict[str, bytes] = {}
_lock = threading.Lock()


def save_file(session_id: str, encrypted_bytes: bytes) -> None:
    with _lock:
        _store[session_id] = encrypted_bytes


def get_file(session_id: str) -> bytes | None:
    with _lock:
        return _store.get(session_id)


def delete_file(session_id: str) -> bool:
    with _lock:
        if session_id in _store:
            del _store[session_id]
            return True
        return False


def file_exists(session_id: str) -> bool:
    with _lock:
        return session_id in _store
        