import firebase_admin
from firebase_admin import credentials, auth
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from utils.config import settings

_firebase_app = None

def init_firebase():
    global _firebase_app
    if _firebase_app is None:
        cred = credentials.Certificate(settings.firebase_credentials_path)
        _firebase_app = firebase_admin.initialize_app(cred)
    return _firebase_app

bearer_scheme = HTTPBearer()

def get_current_firebase_user(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)) -> dict:
    """Verifies the Firebase ID token sent in the Authorization header and
    returns the decoded token (contains uid, email, etc.)."""
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token",
        )
