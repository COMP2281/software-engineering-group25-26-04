# =============================================================================
# AUTH UTILITIES
# =============================================================================

from datetime import datetime, timedelta, timezone
from typing import Optional

import bcrypt

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import Staff, User

ALGORITHM = "HS256"

# tokenUrl tells the OpenAPI /docs UI where to POST for a token
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


# -----------------------------------------------------------------------------
# Password helpers
# -----------------------------------------------------------------------------

def hash_password(plain_password: str) -> str:
    """Return a bcrypt hash of plain_password."""
    return bcrypt.hashpw(plain_password.encode(), bcrypt.gensalt()).decode()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Return True if plain_password matches hashed_password."""
    return bcrypt.checkpw(plain_password.encode(), hashed_password.encode())


# -----------------------------------------------------------------------------
# Token creation
# -----------------------------------------------------------------------------

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Encode data into a signed JWT.

    Args:
        data: Must contain {"sub": "<staff_id as str>"}.
        expires_delta: Override the default expiry from settings.

    Returns:
        Compact serialised JWT string.
    """
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta
        if expires_delta is not None
        else timedelta(hours=settings.TOKEN_EXPIRE_HOURS)
    )
    to_encode["exp"] = expire
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)


# -----------------------------------------------------------------------------
# FastAPI dependency — validates incoming JWT on every protected request
# -----------------------------------------------------------------------------

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> Staff:
    """Decode and validate the Bearer JWT; return the authenticated Staff row.

    Raises HTTP 401 for: missing token, invalid signature, expired token,
    missing 'sub' claim, or no matching User/Staff record in the database.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, settings.SECRET_KEY,
                             algorithms=[ALGORITHM])
        staff_id_str: Optional[str] = payload.get("sub")
        if staff_id_str is None:
            raise credentials_exception
        staff_id = int(staff_id_str)
    except (JWTError, ValueError):
        raise credentials_exception

    # Confirm the User record still exists (account not deleted/revoked)
    user_result = await db.execute(
        select(User).where(User.staff_id == staff_id)
    )
    if user_result.scalar_one_or_none() is None:
        raise credentials_exception

    # Return the linked Staff record
    staff_result = await db.execute(
        select(Staff).where(Staff.staff_id == staff_id)
    )
    staff = staff_result.scalar_one_or_none()
    if staff is None:
        raise credentials_exception

    return staff
