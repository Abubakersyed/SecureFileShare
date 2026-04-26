import os
import hashlib
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

_MASTER_SECRET = os.getenv("SECRET_KEY", "default-secret-change-this").encode()
_AES_KEY = hashlib.sha256(_MASTER_SECRET).digest()


def encrypt_file(file_bytes: bytes) -> bytes:
    iv = os.urandom(16)
    cipher = AES.new(_AES_KEY, AES.MODE_CBC, iv)
    encrypted = cipher.encrypt(pad(file_bytes, AES.block_size))
    return iv + encrypted


def decrypt_file(encrypted_bytes: bytes) -> bytes:
    iv = encrypted_bytes[:16]
    encrypted_content = encrypted_bytes[16:]
    cipher = AES.new(_AES_KEY, AES.MODE_CBC, iv)
    return unpad(cipher.decrypt(encrypted_content), AES.block_size)