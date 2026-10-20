import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.api.deps import get_current_user_dep, get_current_admin_dep
from app.core.database import get_db
from app.models.banner import Banner
from app.models.user import User
from app.models.restaurant import Restaurant
from app.schemas.banner import BannerCreate, BannerResponse

router = APIRouter()

@router.get("", response_model=list[BannerResponse])
async def get_approved_banners(db: AsyncSession = Depends(get_db)):
    """
    Get all approved banners. (Public endpoint for Customer app)
    """
    result = await db.execute(
        select(Banner).where(Banner.is_approved == True).order_by(Banner.created_at.desc())
    )
    return result.scalars().all()

@router.get("/admin", response_model=list[BannerResponse])
async def get_all_banners_for_admin(
    admin: User = Depends(get_current_admin_dep),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all banners (approved & pending). (Admin only)
    """
    result = await db.execute(
        select(Banner).order_by(Banner.created_at.desc())
    )
    return result.scalars().all()

@router.get("/merchant", response_model=list[BannerResponse])
async def get_merchant_banners(
    merchant: User = Depends(get_current_user_dep),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all banners created by the logged-in merchant.
    """
    result = await db.execute(
        select(Banner).where(Banner.created_by == merchant.id).order_by(Banner.created_at.desc())
    )
    return result.scalars().all()

@router.post("", response_model=BannerResponse, status_code=status.HTTP_201_CREATED)
async def create_banner(
    banner_in: BannerCreate,
    user: User = Depends(get_current_user_dep),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new banner.
    - Admin: automatically approved.
    - Merchant: requires admin approval.
    """
    creator_name = "Admin"
    is_approved = False
    
    if user.role == "admin":
        is_approved = True
    elif user.role == "merchant":
        # Find their restaurant name to set as creator name
        rest_result = await db.execute(
            select(Restaurant).where(Restaurant.owner_id == user.id)
        )
        rest = rest_result.scalars().first()
        if rest:
            creator_name = rest.name
        else:
            creator_name = user.name or "Merchant"
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Admins or Merchants can create banners"
        )
        
    db_banner = Banner(
        title=banner_in.title,
        subtitle=banner_in.subtitle,
        tag=banner_in.tag,
        button_text=banner_in.button_text,
        route=banner_in.route,
        image_url=banner_in.image_url,
        colors=banner_in.colors,
        created_by=user.id,
        creator_name=creator_name,
        is_approved=is_approved
    )
    
    db.add(db_banner)
    await db.flush()
    return db_banner

@router.put("/{banner_id}/approve", response_model=BannerResponse)
async def approve_banner(
    banner_id: uuid.UUID,
    admin: User = Depends(get_current_admin_dep),
    db: AsyncSession = Depends(get_db)
):
    """
    Approve a pending banner. (Admin only)
    """
    banner_result = await db.execute(
        select(Banner).where(Banner.id == banner_id)
    )
    banner = banner_result.scalars().first()
    if not banner:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Banner not found"
        )
        
    banner.is_approved = True
    await db.flush()
    return banner

@router.delete("/{banner_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_banner(
    banner_id: uuid.UUID,
    user: User = Depends(get_current_user_dep),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete a banner.
    - Admin: can delete any banner.
    - Merchant: can delete their own banners.
    """
    banner_result = await db.execute(
        select(Banner).where(Banner.id == banner_id)
    )
    banner = banner_result.scalars().first()
    if not banner:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Banner not found"
        )
        
    if user.role != "admin" and banner.created_by != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this banner"
        )
        
    await db.delete(banner)
    await db.flush()
