"""Optional Redis/Celery infrastructure with safe local fallbacks.

The web process remains usable without Redis during development. Production
deployments should set REDIS_URL and run `celery -A infrastructure.celery_app worker`.
"""
import json
import os
import time
from collections import defaultdict, deque
from celery import Celery

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL", REDIS_URL)
CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND", REDIS_URL)
celery_app = Celery("nirpr", broker=CELERY_BROKER_URL, backend=CELERY_RESULT_BACKEND)
celery_app.conf.update(task_serializer="json", accept_content=["json"], result_serializer="json",
                       timezone=os.getenv("TZ", "Africa/Lagos"), enable_utc=True)

try:
    import redis.asyncio as redis
    redis_client = redis.from_url(REDIS_URL, decode_responses=True, socket_connect_timeout=1)
except Exception:
    redis_client = None

_memory_windows = defaultdict(deque)


async def rate_limit(key: str, limit: int, window_seconds: int) -> bool:
    """Return True when allowed. Uses atomic Redis counters when available."""
    if redis_client:
        try:
            count = await redis_client.incr(f"rate:{key}")
            if count == 1:
                await redis_client.expire(f"rate:{key}", window_seconds)
            return count <= limit
        except Exception:
            pass
    now = time.monotonic(); window = _memory_windows[key]
    while window and window[0] <= now - window_seconds:
        window.popleft()
    if len(window) >= limit:
        return False
    window.append(now); return True


async def cache_set(key: str, value, ttl: int = 300):
    if redis_client:
        try: await redis_client.setex(key, ttl, json.dumps(value))
        except Exception: pass


async def heartbeat(attempt_id: int, payload: dict, ttl: int = 90):
    await cache_set(f"exam:heartbeat:{attempt_id}", payload, ttl)


@celery_app.task(name="nirpr.send_email")
def send_email_task(kind: str, kwargs: dict):
    import email_utils
    sender = getattr(email_utils, kind)
    return sender(**kwargs)

