from fastapi import APIRouter, HTTPException, Query, Response
import httpx
from urllib.parse import quote

from app.config import get_settings

router = APIRouter()
settings = get_settings()


def _require_key():
    if not settings.TOMTOM_API_KEY:
        raise HTTPException(status_code=503, detail="Maps service not configured")


@router.get("/tile/{z}/{x}/{y}.png")
async def tile(z: int, x: int, y: int):
    _require_key()
    url = f"https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key={settings.TOMTOM_API_KEY}"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url)
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail="Maps provider error")
        return Response(content=resp.content, media_type=resp.headers.get("content-type", "image/png"))


@router.get("/search")
async def search(q: str = Query(..., min_length=1), lat: float | None = None, lon: float | None = None, limit: int = 8):
    _require_key()
    params = {"key": settings.TOMTOM_API_KEY, "query": q, "limit": limit, "countrySet": "GH", "language": "en-GB"}
    if lat is not None and lon is not None:
        params["lat"] = lat
        params["lon"] = lon
        params["radius"] = 50000
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get("https://api.tomtom.com/search/2/search/" + quote(q) + ".json", params=params)
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail="Maps provider error")
        return resp.json()


@router.get("/reverse")
async def reverse(lat: float, lon: float, radius: int = 100):
    _require_key()
    params = {"key": settings.TOMTOM_API_KEY, "language": "en-GB", "radius": radius}
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(f"https://api.tomtom.com/search/2/reverseGeocode/{lat},{lon}.json", params=params)
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail="Maps provider error")
        return resp.json()


@router.get("/route")
async def route(fromLat: float, fromLon: float, toLat: float, toLon: float, travelMode: str = "car"):
    _require_key()
    params = {
        "key": settings.TOMTOM_API_KEY,
        "language": "en-GB",
        "instructionsType": "text",
        "routeType": "fastest",
        "traffic": "true",
        "travelMode": travelMode,
    }
    async with httpx.AsyncClient(timeout=15.0) as client:
        resp = await client.get(
            f"https://api.tomtom.com/routing/1/calculateRoute/{fromLat},{fromLon}:{toLat},{toLon}/json",
            params=params,
        )
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail="Maps provider error")
        return resp.json()
