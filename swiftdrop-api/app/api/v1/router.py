from fastapi import APIRouter

from app.api.v1 import (
    admin,
    auth,
    categories,
    customer,
    dispatch,
    merchants,
    notifications,
    orders,
    payments,
    reviews,
    rider_profile,
    riders,
    restaurants,
    setup,
)

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth.router)
api_router.include_router(orders.router)
api_router.include_router(payments.router)
api_router.include_router(riders.router)
api_router.include_router(dispatch.router)
api_router.include_router(restaurants.router)
api_router.include_router(categories.router)
api_router.include_router(merchants.router)
api_router.include_router(admin.router)
api_router.include_router(notifications.router)
api_router.include_router(reviews.router)
api_router.include_router(customer.router)
api_router.include_router(rider_profile.router)
api_router.include_router(setup.router)
