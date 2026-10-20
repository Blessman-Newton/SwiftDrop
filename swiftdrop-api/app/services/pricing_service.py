"""Server-authoritative pricing for non-restaurant orders."""

from math import asin, cos, radians, sin, sqrt
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException
from app.models.cosmetic import CosmeticProduct
from app.models.settings import PlatformSetting

DEFAULT_GAS_PRICES = {
    "6 kg": 75.0,
    "12.5 kg": 150.0,
    "14 kg": 180.0,
    "22 kg": 280.0,
    "50 kg": 600.0,
}


def _distance_km(metadata: dict[str, Any], pickup_lat: float | None, pickup_lng: float | None,
                 delivery_lat: float | None, delivery_lng: float | None) -> float:
    supplied = metadata.get("distance_km")
    if supplied is not None:
        raise BadRequestException("Distance must be calculated by the server")
    if None in (pickup_lat, pickup_lng, delivery_lat, delivery_lng):
        return 0.0
    lat1, lon1, lat2, lon2 = map(float, (pickup_lat, pickup_lng, delivery_lat, delivery_lng))
    dlat, dlon = radians(lat2 - lat1), radians(lon2 - lon1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    return 6371.0 * 2 * asin(sqrt(a))


async def price_cosmetics(db: AsyncSession, items: list[Any]) -> tuple[float, list[dict[str, Any]]]:
    ids = [item.cosmetic_product_id for item in items]
    if not ids or any(not item_id for item_id in ids):
        raise BadRequestException("Cosmetics items must include catalog product IDs")
    products = (await db.execute(
        select(CosmeticProduct).where(
            CosmeticProduct.id.in_(ids), CosmeticProduct.is_available.is_(True)
        )
    )).scalars().all()
    by_id = {str(product.id): product for product in products}
    if len(by_id) != len(set(ids)):
        raise BadRequestException("One or more cosmetics products are unavailable")
    priced = []
    subtotal = 0.0
    for item in items:
        product = by_id[item.cosmetic_product_id]
        price = round(float(product.price), 2)
        subtotal += price * item.quantity
        priced.append({"name": product.name, "quantity": item.quantity, "price": price,
                       "cosmetic_product_id": str(product.id), "notes": item.notes})
    return round(subtotal, 2), priced


async def price_gas(db: AsyncSession, metadata: dict[str, Any]) -> tuple[float, float]:
    size = metadata.get("cylinder_size")
    if not isinstance(size, str):
        raise BadRequestException("Gas orders must include a cylinder size")
    setting = (await db.execute(
        select(PlatformSetting).where(PlatformSetting.key == "gas_refill_prices")
    )).scalar_one_or_none()
    catalog = setting.value if setting and isinstance(setting.value, dict) else DEFAULT_GAS_PRICES
    if size not in catalog:
        raise BadRequestException("Unsupported gas cylinder size")
    quantity = metadata.get("quantity", 1)
    if quantity != 1:
        raise BadRequestException("Only one gas cylinder may be booked per order")
    speed = metadata.get("delivery_speed", "Standard")
    if speed not in ("Standard", "Express"):
        raise BadRequestException("Unsupported gas delivery speed")
    return round(float(catalog[size]), 2), 25.0 if speed == "Express" else 15.0


async def price_parcel(metadata: dict[str, Any], pickup_lat: float | None, pickup_lng: float | None,
                       delivery_lat: float | None, delivery_lng: float | None) -> tuple[float, float]:
    if metadata.get("delivery_speed", "Standard") not in ("Standard", "Express"):
        raise BadRequestException("Unsupported parcel delivery speed")
    weight = float(metadata.get("weight_kg", 1))
    if weight <= 0 or weight > 50:
        raise BadRequestException("Parcel weight must be between 0 and 50 kg")
    distance = _distance_km(metadata, pickup_lat, pickup_lng, delivery_lat, delivery_lng)
    subtotal = 10.0 + max(0.0, weight - 1.0) * 2.0
    fee = 8.0 + distance * 1.5 + (13.0 if metadata.get("delivery_speed") == "Express" else 0.0)
    return round(subtotal, 2), round(fee, 2)
