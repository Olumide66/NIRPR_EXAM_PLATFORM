"""
NIRPR RSO Examination Platform - Authentication & Authorization
"""

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import os
import secrets

from database import get_db
from models import User, UserRole, AuditLog, AuthSession


VERIFICATION_TOKEN_EXPIRE_HOURS = int(os.getenv("VERIFICATION_TOKEN_EXPIRE_HOURS", "24"))
PASSWORD_RESET_TOKEN_EXPIRE_MINUTES = int(os.getenv("PASSWORD_RESET_TOKEN_EXPIRE_MINUTES", "60"))
SECRET_KEY = os.getenv("SECRET_KEY", "nirpr-rso-platform-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "480"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer(auto_error=False)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None


async def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = decode_token(credentials.credentials)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )

    session_id = payload.get("sid")
    if session_id:
        session_record = (await db.execute(select(AuthSession).where(AuthSession.id == session_id))).scalar_one_or_none()
        if (not session_record or session_record.revoked_at or session_record.expires_at < datetime.utcnow()):
            raise HTTPException(status_code=401, detail="Session expired or revoked")
        session_record.last_seen_at = datetime.utcnow()

    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated",
        )

    # Transient attribute (not persisted) set when this token was issued via
    # the admin "log in as candidate" feature — lets endpoints tell an
    # impersonated session apart from the candidate's own real login.
    user.impersonated_by = payload.get("impersonated_by")

    allowed_while_temporary = {
        "/api/auth/me", "/api/auth/change-temporary-password",
        "/api/auth/logout", "/api/auth/sessions",
    }
    if user.must_change_password and request.url.path not in allowed_while_temporary:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="PASSWORD_CHANGE_REQUIRED: Replace your temporary password before using the portal.",
        )

    return user


async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


def require_role(*roles: UserRole):
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {[r.value for r in roles]}",
            )
        return current_user
    return role_checker


require_admin = require_role(UserRole.SUPER_ADMIN, UserRole.ADMIN)
require_examiner = require_role(UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.EXAMINER)
require_candidate = require_role(UserRole.CANDIDATE)
require_any = require_role(
    UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.EXAMINER, UserRole.CANDIDATE
)


async def require_real_candidate(current_user: User = Depends(require_candidate)) -> User:
    """Same as require_candidate, but also blocks the request if this session
    is an admin impersonating the candidate. Used specifically on the
    exam-taking endpoints (start / answer / submit) so an admin using "log
    in as candidate" to check what the portal looks like can never actually
    sit or complete an exam on the candidate's behalf — that would be a
    serious integrity problem for a certification platform. Browsing the
    dashboard and results while impersonating is still allowed."""
    if getattr(current_user, "impersonated_by", None):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Exam-taking actions are disabled while viewing as this candidate via admin impersonation. "
                   "Log in as the candidate directly (or ask them to) to sit or submit an exam.",
        )
    return current_user


async def log_audit(
    db: AsyncSession,
    action: str,
    user_id: Optional[int] = None,
    entity_type: Optional[str] = None,
    entity_id: Optional[int] = None,
    details: Optional[dict] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None
):
    log = AuditLog(
        user_id=user_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        details=details or {},
        ip_address=ip_address,
        user_agent=user_agent,
    )
    db.add(log)
    await db.commit()


def generate_secure_token() -> str:
    """URL-safe random token used for email verification / password reset links."""
    return secrets.token_urlsafe(32)


def get_client_ip(request: Request) -> str:
    x_forwarded_for = request.headers.get("X-Forwarded-For")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.client.host if request.client else "unknown"
