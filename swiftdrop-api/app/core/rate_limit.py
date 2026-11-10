import time
from collections import defaultdict, deque
from threading import Lock

from fastapi import HTTPException, Request, status


class SimpleRateLimiter:
    def __init__(self):
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def check(self, key: str, limit: int, window_seconds: int) -> None:
        now = time.time()
        with self._lock:
            q = self._hits[key]
            cutoff = now - window_seconds
            while q and q[0] < cutoff:
                q.popleft()
            if len(q) >= limit:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many requests. Please try again later.",
                )
            q.append(now)


limiter = SimpleRateLimiter()


def rate_limit(limit: int, window_seconds: int, scope: str):
    async def _dep(request: Request):
        ip = request.client.host if request.client else "unknown"
        limiter.check(f"{scope}:{ip}", limit, window_seconds)

    return _dep
