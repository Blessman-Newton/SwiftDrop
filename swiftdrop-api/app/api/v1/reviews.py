from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.core.database import get_db
from app.models.order import Order
from app.models.restaurant import Restaurant
from app.models.review import Review
from app.models.user import User
from app.schemas.review import (
    CreateReviewRequest,
    ReviewListResponse,
    ReviewResponse,
    RiderRatingSummary,
    RestaurantRatingSummary,
)

router = APIRouter(prefix="/reviews", tags=["reviews"])


@router.post("", response_model=ReviewResponse)
async def create_review(
    request: CreateReviewRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    order_id = UUID(request.order_id)
    order_q = select(Order).where(Order.id == order_id, Order.customer_id == current_user.id)
    order_result = await db.execute(order_q)
    order = order_result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found or not yours")

    existing_q = select(Review).where(
        Review.order_id == order_id,
        Review.customer_id == current_user.id,
        Review.review_type == request.review_type,
    )
    existing = (await db.execute(existing_q)).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=409, detail="Already reviewed this order")

    review = Review(
        order_id=order_id,
        customer_id=current_user.id,
        rider_id=order.rider_id,
        restaurant_id=None,
        rating=request.rating,
        comment=request.comment,
        review_type=request.review_type,
    )
    db.add(review)
    await db.flush()

    return ReviewResponse(
        id=str(review.id),
        order_id=str(review.order_id),
        customer_name=current_user.name or "Customer",
        rider_name=None,
        restaurant_name=None,
        rating=review.rating,
        comment=review.comment,
        review_type=review.review_type,
        created_at=review.created_at,
    )


@router.get("", response_model=ReviewListResponse)
async def list_reviews(
    review_type: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    query = select(Review).where(Review.customer_id == current_user.id)
    if review_type:
        query = query.where(Review.review_type == review_type)
    query = query.order_by(Review.created_at.desc())

    result = await db.execute(query)
    reviews = result.scalars().all()

    avg_q = select(func.avg(Review.rating)).where(Review.customer_id == current_user.id)
    avg_rating = float((await db.execute(avg_q)).scalar() or 0)

    total_q = select(func.count(Review.id)).where(Review.customer_id == current_user.id)
    total = (await db.execute(total_q)).scalar() or 0

    return ReviewListResponse(
        reviews=[
            ReviewResponse(
                id=str(r.id),
                order_id=str(r.order_id),
                customer_name=current_user.name or "Customer",
                rider_name=None,
                restaurant_name=None,
                rating=r.rating,
                comment=r.comment,
                review_type=r.review_type,
                created_at=r.created_at,
            )
            for r in reviews
        ],
        average_rating=avg_rating,
        total_reviews=total,
    )


@router.get("/rider/{rider_id}", response_model=RiderRatingSummary)
async def get_rider_rating(
    rider_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    avg_q = select(func.avg(Review.rating)).where(
        Review.rider_id == rider_id, Review.review_type == "rider"
    )
    avg_rating = float((await db.execute(avg_q)).scalar() or 0)

    total_q = select(func.count(Review.id)).where(
        Review.rider_id == rider_id, Review.review_type == "rider"
    )
    total = (await db.execute(total_q)).scalar() or 0

    dist_q = (
        select(Review.rating, func.count(Review.id))
        .where(Review.rider_id == rider_id, Review.review_type == "rider")
        .group_by(Review.rating)
    )
    dist_result = await db.execute(dist_q)
    distribution = {str(row[0]): row[1] for row in dist_result.all()}

    return RiderRatingSummary(
        rider_id=str(rider_id),
        average_rating=avg_rating,
        total_reviews=total,
        rating_distribution=distribution,
    )
