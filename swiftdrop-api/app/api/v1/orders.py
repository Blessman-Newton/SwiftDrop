from uuid import UUID

from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_dep
from app.core.database import get_db
from app.models.user import User
from app.schemas.order import CreateOrderRequest, OrderResponse
from app.services import order_service

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post("", response_model=OrderResponse)
async def create_order(
    request: CreateOrderRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await order_service.create_order(db, current_user.id, request)


@router.get("", response_model=list[OrderResponse])
async def list_orders(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await order_service.list_orders(db, customer_id=current_user.id)


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await order_service.get_order(db, order_id)


@router.patch("/{order_id}/cancel", response_model=OrderResponse)
async def cancel_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_dep),
):
    return await order_service.cancel_order(db, order_id, current_user.id)


@router.get("/{order_id}/tracking", response_class=HTMLResponse)
async def public_tracking_page(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    order = await order_service.get_order(db, order_id)
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>SwiftDrop Live Tracking</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <style>
            body {{ margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #f3f4f6; }}
            #map {{ height: 60vh; width: 100%; }}
            .details {{ padding: 24px; box-sizing: border-box; background: white; border-top-left-radius: 20px; border-top-right-radius: 20px; margin-top: -20px; position: relative; z-index: 1000; box-shadow: 0 -4px 10px rgba(0,0,0,0.05); }}
            .title {{ font-size: 22px; font-weight: 800; margin-bottom: 8px; color: #111827; }}
            .status {{ display: inline-block; padding: 6px 12px; border-radius: 9999px; font-size: 12px; font-weight: 700; text-transform: uppercase; background: #DEF7EC; color: #03543F; margin-bottom: 16px; }}
            .info {{ font-size: 14px; color: #4B5563; border-top: 1px solid #E5E7EB; padding-top: 16px; }}
            .info-item {{ margin-bottom: 12px; display: flex; }}
            .info-label {{ font-weight: 700; color: #111827; width: 80px; flex-shrink: 0; }}
            .info-value {{ color: #4B5563; }}
        </style>
    </head>
    <body>
        <div id="map"></div>
        <div class="details">
            <div class="title">{order.restaurant_name or 'Parcel Booking'}</div>
            <div class="status">{order.status}</div>
            <div class="info">
                <div class="info-item"><span class="info-label">Pickup:</span> <span class="info-value">{order.pickup_address}</span></div>
                <div class="info-item"><span class="info-label">Delivery:</span> <span class="info-value">{order.delivery_address}</span></div>
                <div class="info-item"><span class="info-label">Rider:</span> <span class="info-value">{order.rider_name or 'Assigning rider...'} {f"({order.rider_phone})" if order.rider_phone else ""}</span></div>
            </div>
        </div>
        <script>
            const map = L.map('map').setView([{order.delivery_lat or 7.3349}, {order.delivery_lng or -2.3266}], 15);
            L.tileLayer('https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png', {{
                maxZoom: 19,
                attribution: '© OpenStreetMap'
            }}).addTo(map);

            const deliveryMarker = L.marker([{order.delivery_lat or 7.3349}, {order.delivery_lng or -2.3266}]).addTo(map)
                .bindPopup('Delivery Address').openPopup();

            const pickupMarker = L.marker([{order.pickup_lat or 7.3349}, {order.pickup_lng or -2.3266}]).addTo(map)
                .bindPopup('Pickup Address');

            let riderMarker = null;

            function pollLocation() {{
                fetch(`/api/v1/orders/{order.id}/public-status`)
                    .then(res => res.json())
                    .then(data => {{
                        document.querySelector('.status').innerText = data.status;
                        if (data.rider_lat && data.rider_lng) {{
                            const pos = [data.rider_lat, data.rider_lng];
                            if (!riderMarker) {{
                                riderMarker = L.marker(pos, {{
                                    icon: L.icon({{
                                        iconUrl: 'https://cdn-icons-png.flaticon.com/512/2972/2972185.png',
                                        iconSize: [36, 36],
                                        iconAnchor: [18, 18]
                                    }})
                                }}).addTo(map).bindPopup('Rider Current Location').openPopup();
                            } else {{
                                riderMarker.setLatLng(pos);
                            }}
                            map.panTo(pos);
                        }}
                    }});
            }}
            pollLocation();
            setInterval(pollLocation, 5000);
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)


@router.get("/{order_id}/public-status")
async def get_public_status(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    order = await order_service.get_order(db, order_id)
    return {
        "status": order.status,
        "rider_lat": order.rider_lat,
        "rider_lng": order.rider_lng,
    }

