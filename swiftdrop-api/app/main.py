import logging
import time
import traceback
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1.router import api_router
from app.api.v1.setup import run_migrations
from app.config import get_settings
from app.core.database import Base, database_url, engine, get_masked_db_target
from app.core.exceptions import AppException

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)
logger = logging.getLogger("swiftdrop")
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting %s API", settings.APP_NAME)
    logger.info("Database target: %s", get_masked_db_target(database_url))
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables ensured")
    try:
        done = await run_migrations()
        logger.info("Auto-migrations applied: %s", ", ".join(done) if done else "none")
    except Exception:
        logger.exception("Auto-migration error")
        raise
    yield
    logger.info("Shutting down %s API", settings.APP_NAME)


app = FastAPI(
    title=settings.APP_NAME,
    description="Multi-role delivery platform API",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.APP_ENV == "development" else None,
    redoc_url="/redoc" if settings.APP_ENV == "development" else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=settings.cors_allow_credentials,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Requested-With", "X-Paystack-Signature"],
)


@app.middleware("http")
async def request_timing_and_safety(request: Request, call_next):
    started = time.perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        logger.exception("Unhandled request error: %s %s", request.method, request.url.path)
        raise
    duration_ms = (time.perf_counter() - started) * 1000
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    if settings.APP_ENV == "production":
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    logger.info("%s %s -> %s %.1fms", request.method, request.url.path, response.status_code, duration_ms)
    return response


@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "error_code": exc.__class__.__name__},
        headers=exc.headers,
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors()[:20]:
        errors.append({"loc": err.get("loc"), "msg": err.get("msg"), "type": err.get("type")})
    return JSONResponse(status_code=422, content={"detail": "Validation error", "errors": errors})


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
    detail = "Internal server error"
    if settings.APP_ENV == "development":
        detail = str(exc)
    return JSONResponse(status_code=500, content={"detail": detail, "error_code": "InternalServerError"})


app.include_router(api_router)


@app.get("/")
async def root():
    return {"status": "online", "service": settings.APP_NAME}


@app.get("/health")
async def health():
    return {"status": "healthy", "service": settings.APP_NAME}
