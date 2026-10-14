"""
Chapter 09 Lab: Event-Driven Microservices Architecture
Features an Order Service producer and an Analytics / Notification consumer using Redis Pub/Sub.
"""

import asyncio
import json
import logging
from typing import Optional
from fastapi import FastAPI, BackgroundTasks, status
from pydantic import BaseModel
import redis.asyncio as aioredis

# Logging configuration
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger("microservice_event_bus")

REDIS_URL = "redis://localhost:6379"
CHANNEL_NAME = "order_events"

app = FastAPI(title="Lab 09: Microservices Event Bus", version="1.0.0")
redis_client: Optional[aioredis.Redis] = None

# ---------------------------------------------------------------------------
# Redis Connection Management
# ---------------------------------------------------------------------------
@app.on_event("startup")
async def startup_event():
    global redis_client
    try:
        redis_client = aioredis.from_url(REDIS_URL, decode_responses=True)
        logger.info("Connected to Redis Event Broker")
    except Exception as e:
        logger.warning(f"Redis connection failed (standalone mode active): {e}")

@app.on_event("shutdown")
async def shutdown_event():
    if redis_client:
        await redis_client.close()

# ---------------------------------------------------------------------------
# Pydantic Schemas
# ---------------------------------------------------------------------------
class OrderCreate(BaseModel):
    user_id: str
    item_id: str
    quantity: int
    amount: float

class OrderResponse(BaseModel):
    message: str
    order_id: str
    status: str

# ---------------------------------------------------------------------------
# Asynchronous Event Producer & Consumer Simulation
# ---------------------------------------------------------------------------
async def publish_event(event_type: str, payload: dict):
    """Publishes an event payload to the Redis channel."""
    event_data = {
        "event_type": event_type,
        "timestamp": asyncio.get_event_loop().time(),
        "payload": payload,
    }
    if redis_client:
        try:
            await redis_client.publish(CHANNEL_NAME, json.dumps(event_data))
            logger.info(f" [Event Published] Type: '{event_type}' -> Channel: '{CHANNEL_NAME}'")
        except Exception as err:
            logger.error(f"Failed to publish event to Redis: {err}")
    else:
        logger.info(f" [Event Simulated] Type: '{event_type}' -> Payload: {payload}")

# ---------------------------------------------------------------------------
# Route Handlers
# ---------------------------------------------------------------------------
@app.post("/api/v1/orders", response_model=OrderResponse, status_code=status.HTTP_202_ACCEPTED, tags=["Order Producer"])
async def create_order(order: OrderCreate, background_tasks: BackgroundTasks):
    order_id = f"ord_{int(asyncio.get_event_loop().time() * 1000)}"
    order_payload = {
        "order_id": order_id,
        "user_id": order.user_id,
        "item_id": order.item_id,
        "quantity": order.quantity,
        "amount": order.amount,
        "status": "PENDING",
    }

    # Offload non-blocking event publishing to background task
    background_tasks.add_task(publish_event, "ORDER_CREATED", order_payload)

    return OrderResponse(
        message="Order submitted and event queued for asynchronous processing.",
        order_id=order_id,
        status="ACCEPTED",
    )

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy", "service": "order-event-producer"}
