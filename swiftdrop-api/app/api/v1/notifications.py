from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.core.database import get_db
from app.models.notification import Notification
from app.models.user import User
from app.schemas.notification import (
    NotificationListResponse,
    NotificationResponse,
    SendNotificationRequest,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=NotificationListResponse)
async def list_notifications(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    query = (
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .limit(50)
    )
    result = await db.execute(query)
    notifications = result.scalars().all()

    unread_q = select(func.count(Notification.id)).where(
        Notification.user_id == current_user.id,
        Notification.is_read == False,
    )
    unread_count = (await db.execute(unread_q)).scalar() or 0

    return NotificationListResponse(
        notifications=[
            NotificationResponse(
                id=str(n.id),
                title=n.title,
                body=n.body,
                type=n.type,
                is_read=n.is_read,
                metadata=n.metadata_,
                created_at=n.created_at,
            )
            for n in notifications
        ],
        unread_count=unread_count,
    )


@router.post("/{notification_id}/read")
async def mark_notification_read(
    notification_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    query = select(Notification).where(
        Notification.id == notification_id,
        Notification.user_id == current_user.id,
    )
    result = await db.execute(query)
    notification = result.scalar_one_or_none()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")

    notification.is_read = True
    await db.flush()
    return {"message": "Notification marked as read"}


@router.post("/read-all")
async def mark_all_read(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    stmt = (
        update(Notification)
        .where(Notification.user_id == current_user.id, Notification.is_read == False)
        .values(is_read=True)
    )
    await db.execute(stmt)
    await db.flush()
    return {"message": "All notifications marked as read"}


@router.post("/send")
async def send_notification(
    request: SendNotificationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    notification = Notification(
        user_id=UUID(request.user_id),
        title=request.title,
        body=request.body,
        type=request.type,
    )
    db.add(notification)
    await db.flush()
    return {"message": "Notification sent", "id": str(notification.id)}
