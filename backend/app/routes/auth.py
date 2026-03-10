# =============================================================================
# AUTH ROUTES
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Staff, User
from app.utils.auth import create_access_token, verify_password, get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


class TokenResponse(BaseModel):
    access_token: str
    token_type: str


class CurrentUserResponse(BaseModel):
    staff_id: int
    email: str
    first_name: str
    last_name: str
    role: str


@router.post("/login", response_model=TokenResponse)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    """Exchange email + password for a JWT access token.

    OAuth2PasswordRequestForm uses the field name 'username' for the
    email address. The client must POST application/x-www-form-urlencoded
    with fields 'username' (email) and 'password'.
    """
    # Deliberately use the same error for wrong email OR wrong password
    # to avoid leaking whether an email exists in the system
    auth_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid email or password",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # Step 1 — find staff by email
    result = await db.execute(
        select(Staff).where(Staff.email == form_data.username.lower().strip())
    )
    staff = result.scalar_one_or_none()
    if staff is None:
        raise auth_error

    # Step 2 — find the User (credential) record linked to this staff member
    result = await db.execute(select(User).where(User.staff_id == staff.staff_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise auth_error

    # Step 3 — verify bcrypt hash
    if not verify_password(form_data.password, user.password):
        raise auth_error

    # Step 4 — issue token with staff_id as the subject claim
    token = create_access_token(data={"sub": str(staff.staff_id)})
    return TokenResponse(access_token=token, token_type="bearer")


@router.get("/me", response_model=CurrentUserResponse)
async def get_current_user_info(
    staff: Staff = Depends(get_current_user),
) -> CurrentUserResponse:
    """Get current authenticated user's information including role."""
    return CurrentUserResponse(
        staff_id=staff.staff_id,
        email=staff.email,
        first_name=staff.first_name,
        last_name=staff.last_name,
        role=staff.role,
    )
