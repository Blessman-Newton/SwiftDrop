from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from uuid import UUID

from app.core.database import get_db
from app.models.restaurant import MenuItem, PromoCode, Restaurant
from app.models.category import Category
from app.schemas.restaurant import (
    MenuItemResponse,
    PromoCodeResponse,
    RestaurantListResponse,
    RestaurantResponse,
    ValidatePromoRequest,
    ValidatePromoResponse,
)
from app.schemas.category import CategoryResponse

router = APIRouter(prefix="/restaurants", tags=["restaurants"])


@router.get("", response_model=list[RestaurantListResponse])
async def list_restaurants(
    search: str | None = None,
    tag: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    query = select(Restaurant).where(Restaurant.is_active == True)

    if search:
        query = query.where(Restaurant.name.ilike(f"%{search}%"))

    if tag:
        query = query.where(Restaurant.tags.op("@>")(f'["{tag}"]'))

    query = query.order_by(Restaurant.rating.desc())
    result = await db.execute(query)
    restaurants = result.scalars().all()

    response = []
    for r in restaurants:
        count_q = select(func.count(MenuItem.id)).where(
            MenuItem.restaurant_id == r.id, MenuItem.is_available == True
        )
        count_result = await db.execute(count_q)
        menu_count = count_result.scalar() or 0
        response.append(
            RestaurantListResponse(
                id=str(r.id),
                name=r.name,
                slug=r.slug,
                description=r.description,
                image_url=r.image_url,
                address=r.address,
                rating=float(r.rating),
                delivery_time=r.delivery_time,
                delivery_fee=float(r.delivery_fee),
                minimum_order=float(r.minimum_order),
                tags=r.tags or [],
                is_active=r.is_active,
                menu_item_count=menu_count,
            )
        )
    return response


@router.get("/{restaurant_id}", response_model=RestaurantResponse)
async def get_restaurant(
    restaurant_id: str,
    db: AsyncSession = Depends(get_db),
):
    query = (
        select(Restaurant)
        .options(selectinload(Restaurant.menu_items))
        .where(Restaurant.id == restaurant_id)
    )
    result = await db.execute(query)
    restaurant = result.scalar_one_or_none()

    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    return RestaurantResponse(
        id=str(restaurant.id),
        name=restaurant.name,
        slug=restaurant.slug,
        description=restaurant.description,
        image_url=restaurant.image_url,
        logo_url=restaurant.logo_url,
        address=restaurant.address,
        latitude=restaurant.latitude,
        longitude=restaurant.longitude,
        rating=float(restaurant.rating),
        delivery_time=restaurant.delivery_time,
        delivery_fee=float(restaurant.delivery_fee),
        minimum_order=float(restaurant.minimum_order),
        tags=restaurant.tags or [],
        is_active=restaurant.is_active,
        phone=restaurant.phone,
        email=restaurant.email,
        opening_hours=restaurant.opening_hours,
        restaurant_type=restaurant.restaurant_type,
        owner_id=str(restaurant.owner_id) if restaurant.owner_id else None,
        created_at=restaurant.created_at,
        updated_at=restaurant.updated_at,
    )


@router.get("/{restaurant_id}/menu", response_model=list[MenuItemResponse])
async def get_menu(
    restaurant_id: str,
    category_id: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    query = select(MenuItem).where(
        MenuItem.restaurant_id == restaurant_id,
        MenuItem.is_available == True,
    )
    if category_id:
        query = query.where(MenuItem.category_id == UUID(category_id))

    query = query.order_by(MenuItem.rating.desc())
    result = await db.execute(query)
    items = result.scalars().all()

    return [
        MenuItemResponse(
            id=str(mi.id),
            restaurant_id=str(mi.restaurant_id),
            category_id=str(mi.category_id) if mi.category_id else None,
            name=mi.name,
            description=mi.description,
            price=float(mi.price),
            image_url=mi.image_url,
            is_available=mi.is_available,
            is_vegetarian=mi.is_vegetarian,
            is_spicy=mi.is_spicy,
            rating=float(mi.rating),
            tags=mi.tags or [],
            created_at=mi.created_at,
        )
        for mi in items
    ]


@router.get("/promos/list", response_model=list[PromoCodeResponse])
async def list_promos(db: AsyncSession = Depends(get_db)):
    query = select(PromoCode).where(PromoCode.is_active == True)
    result = await db.execute(query)
    promos = result.scalars().all()
    return [
        PromoCodeResponse(
            id=str(p.id),
            code=p.code,
            description=p.description,
            discount_type=p.discount_type,
            discount_value=float(p.discount_value),
            minimum_order=float(p.minimum_order),
            is_active=p.is_active,
        )
        for p in promos
    ]


@router.post("/promos/validate", response_model=ValidatePromoResponse)
async def validate_promo(
    req: ValidatePromoRequest,
    db: AsyncSession = Depends(get_db),
):
    query = select(PromoCode).where(
        PromoCode.code == req.code.upper(),
        PromoCode.is_active == True,
    )
    result = await db.execute(query)
    promo = result.scalar_one_or_none()

    if not promo:
        return ValidatePromoResponse(valid=False, message="Invalid promo code")

    if req.order_total < float(promo.minimum_order):
        return ValidatePromoResponse(
            valid=False,
            message=f"Minimum order is ${promo.minimum_order:.2f}",
        )

    if promo.max_uses and promo.used_count >= promo.max_uses:
        return ValidatePromoResponse(valid=False, message="Promo code usage limit reached")

    discount_amount = 0.0
    if promo.discount_type == "percentage":
        discount_amount = req.order_total * float(promo.discount_value) / 100
    else:
        discount_amount = float(promo.discount_value)

    return ValidatePromoResponse(
        valid=True,
        code=promo.code,
        discount_type=promo.discount_type,
        discount_value=float(promo.discount_value),
        discount_amount=round(discount_amount, 2),
        message="Promo applied successfully",
    )


@router.get("/categories/list", response_model=list[CategoryResponse])
async def list_categories(
    parent_only: bool = Query(True, description="Only return parent categories"),
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