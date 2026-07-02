from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.api.deps import get_current_user_dep
from app.core.database import get_db
from app.models.category import Category
from app.models.user import User
from app.schemas.category import CategoryResponse, CategoryCreateRequest, CategoryUpdateRequest

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryResponse])
async def list_categories(
    parent_only: bool = True,
    db: AsyncSession = Depends(get_db),
):
    query = select(Category).where(Category.is_active == True)
    if parent_only:
        query = query.where(Category.parent_id.is_(None))
    query = query.order_by(Category.display_order, Category.name)
    result = await db.execute(query)
    categories = result.scalars().all()

    return [
        CategoryResponse(
            id=str(c.id),
            name=c.name,
            slug=c.slug,
            description=c.description,
            image_url=c.image_url,
            display_order=c.display_order,
            is_active=c.is_active,
            parent_id=str(c.parent_id) if c.parent_id else None,
            created_at=c.created_at,
        )
        for c in categories
    ]


@router.get("/all", response_model=list[CategoryResponse])
async def list_all_categories(
    db: AsyncSession = Depends(get_db),
):
    query = select(Category).where(Category.is_active == True).order_by(Category.display_order, Category.name)
    result = await db.execute(query)
    categories = result.scalars().all()

    return [
        CategoryResponse(
            id=str(c.id),
            name=c.name,
            slug=c.slug,
            description=c.description,
            image_url=c.image_url,
            display_order=c.display_order,
            is_active=c.is_active,
            parent_id=str(c.parent_id) if c.parent_id else None,
            created_at=c.created_at,
        )
        for c in categories
    ]


@router.get("/{category_id}", response_model=CategoryResponse)
async def get_category(
    category_id: str,
    db: AsyncSession = Depends(get_db),
):
    query = select(Category).where(Category.id == UUID(category_id))
    result = await db.execute(query)
    category = result.scalar_one_or_none()

    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    return CategoryResponse(
        id=str(category.id),
        name=category.name,
        slug=category.slug,
        description=category.description,
        image_url=category.image_url,
        display_order=category.display_order,
        is_active=category.is_active,
        parent_id=str(category.parent_id) if category.parent_id else None,
        created_at=category.created_at,
    )


@router.post("", response_model=CategoryResponse)
async def create_category(
    request: CategoryCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can create categories")

    # Generate slug from name
    slug = request.name.lower().replace(" ", "-").replace("&", "and")

    category = Category(
        name=request.name,
        slug=slug,
        description=request.description,
        image_url=request.image_url,
        display_order=request.display_order,
        parent_id=UUID(request.parent_id) if request.parent_id else None,
    )
    db.add(category)
    await db.flush()

    return CategoryResponse(
        id=str(category.id),
        name=category.name,
        slug=category.slug,
        description=category.description,
        image_url=category.image_url,
        display_order=category.display_order,
        is_active=category.is_active,
        parent_id=str(category.parent_id) if category.parent_id else None,
        created_at=category.created_at,
    )


@router.patch("/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: str,
    request: CategoryUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can update categories")

    query = select(Category).where(Category.id == UUID(category_id))
    result = await db.execute(query)
    category = result.scalar_one_or_none()

    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    update_data = request.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "parent_id" and value:
            setattr(category, field, UUID(value))
        else:
            setattr(category, field, value)

    await db.flush()

    return CategoryResponse(
        id=str(category.id),
        name=category.name,
        slug=category.slug,
        description=category.description,
        image_url=category.image_url,
        display_order=category.display_order,
        is_active=category.is_active,
        parent_id=str(category.parent_id) if category.parent_id else None,
        created_at=category.created_at,
    )


@router.delete("/{category_id}")
async def delete_category(
    category_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Only admins can delete categories")

    query = select(Category).where(Category.id == UUID(category_id))
    result = await db.execute(query)
    category = result.scalar_one_or_none()

    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    # Soft delete - mark as inactive
    category.is_active = False
    await db.flush()

    return {"message": "Category deleted"}