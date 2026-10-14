# Chapter 09: System Architecture and Microservices

As applications scale in user volume, team size, and feature complexity, system architecture evolves from single-process monoliths to distributed, event-driven microservices networks.

---

## 1. Monolithic vs. Microservices Architectural Patterns

```
      Monolithic Architecture                   Microservices Architecture
┌─────────────────────────────────┐        ┌───────────┐    ┌───────────┐
│  ┌───────────────────────────┐  │        │  Order    │    │  User     │
│  │   UI & Presentation       │  │        │  Service  │    │  Service  │
│  ├───────────────────────────┤  │        └─────┬─────┘    └─────┬─────┘
│  │   Order Logic             │  │              │                │
│  ├───────────────────────────┤  │        ┌─────▼────────────────▼─────┐
│  │   User Logic              │  │        │     Message Broker /       │
│  ├───────────────────────────┤  │        │      Event Bus (Kafka)     │
│  │   Payment Logic           │  │        └─────▲────────────────▲─────┘
│  └─────────────┬─────────────┘  │              │                │
│                │                │        ┌─────┴─────┐    ┌─────┴─────┐
│          ┌─────▼─────┐          │        │ Payment   │    │ Inventory │
│          │ Single DB │          │        │ Service   │    │ Service   │
│          └───────────┘          │        └───────────┘    └───────────┘
└─────────────────────────────────┘

```

| Architectural Attribute | Monolith | Microservices |
| --- | --- | --- |
| **Deployment Unit** | Single executable artifact | Multiple independently deployable services |
| **Data Storage** | Single shared database | Database-per-service paradigm |
| **Scaling Mechanism** | Vertical (scale-up) / Homogeneous Horizontal | Granular scaling per service load profile |
| **Fault Isolation** | Low (Single error can bring down entire app) | High (Faults isolated to specific service) |
| **Operational Overhead** | Low | High (Requires service mesh, CI/CD, monitoring) |

---

## 2. API Gateway & Edge Services Strategy

An API Gateway sits between client applications and backend microservices, serving as the single entry point for traffic management, protocol translation, and security enforcement.

```
                  ┌───────────────────────┐
                  │ Client Applications   │
                  └───────────┬───────────┘
                              │ HTTPS / WSS
                              ▼
                  ┌───────────────────────┐
                  │      API Gateway      │
                  │ (Kong / Envoy / Traefik)
                  └───────────┬───────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │ (Auth / Rate Limit)│ (Service Routing)  │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ User Service    │  │ Order Service   │  │ Payment Service │
│ (Port 8001)     │  │ (Port 8002)     │  │ (Port 8003)     │
└─────────────────┘  └─────────────────┘  └─────────────────┘

```

### Key API Gateway Responsibilities

* **Authentication & Authorization Offloading:** Verifies JWT tokens at the boundary before forwarding requests downstream.
* **Rate Limiting & Throttling:** Enforces sliding-window request limits (e.g., via Redis) to prevent DDoS and resource exhaustion.
* **Dynamic Routing:** Directs requests based on path (`/api/v1/users` $\rightarrow$ User Service), headers, or query parameters.
* **SSL/TLS Termination:** Handles SSL handshakes centrally, reducing CPU load on internal microservices.

---

## 3. Asynchronous Communication & Event-Driven Architecture

In microservices, synchronous HTTP/gRPC calls introduce cascading latency and tight coupling. Asynchronous messaging via **Kafka** or **RabbitMQ** enables loosely coupled, event-driven processing.

```
┌───────────────────┐    Publish    ┌───────────────────┐    Subscribe   ┌───────────────────┐
│   Order Service   │──────────────►│    Event Broker   │───────────────►│ Analytics Service │
│ (Event Producer)  │  "OrderPlaced"│  (Kafka / Redis)  │                └───────────────────┘
└───────────────────┘               └─────────┬─────────┘    Subscribe   ┌───────────────────┐
                                              └─────────────────────────►│ Email Service     │
                                                                         └───────────────────┘

```

### Communication Pattern Comparison

* **Synchronous (REST / gRPC):**
* *Pros:* Simple request/response semantics, immediate failure feedback.
* *Cons:* Tight temporal coupling, latency amplification across chained calls.


* **Asynchronous (Event-Driven / Pub-Sub):**
* *Pros:* High throughput, resilience to service outages, independent service scaling.
* *Cons:* Eventual consistency, complex tracing, duplicate event handling requirements (idempotency).



---

## 4. Resilience Patterns: Circuit Breaker & Retries

To prevent localized service failures from causing system-wide outages, distributed architectures employ the **Circuit Breaker** pattern.

```
                    ┌─────────────────────────┐
                    │      CLOSED State       │
                    │  (Requests flow normally)
                    └────────────┬────────────┘
                                 │
                     Failure threshold exceeded
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │       OPEN State        │
                    │ (Fast failure fallback) │
                    └────────────┬────────────┘
                                 │
                         Cooldown timeout
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │    HALF-OPEN State      │
                    │(Test trial requests)    │
                    └─────────────────────────┘

```

---

## 5. Production Microservices Pattern (FastAPI + Redis Pub/Sub)

```python
import asyncio
import json
import logging
from typing import Optional
from fastapi import FastAPI, BackgroundTasks, status
from pydantic import BaseModel
import redis.asyncio as aioredis

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("order_service")

# Configuration
REDIS_URL = "redis://localhost:6379"
CHANNEL_NAME = "order_events"

app = FastAPI(title="Order Microservice", version="1.0.0")
redis_client: Optional[aioredis.Redis] = None

@app.on_event("startup")
async def startup_event():
    global redis_client
    redis_client = aioredis.from_url(REDIS_URL, decode_responses=True)
    logger.info("Connected to Redis Event Broker")

@app.on_event("shutdown")
async def shutdown_event():
    if redis_client:
        await redis_client.close()

class OrderCreate(BaseModel):
    user_id: str
    item_id: str
    amount: float

# Event Publishing Helper
async def publish_order_event(event_type: str, payload: dict):
    event_data = {
        "event_type": event_type,
        "payload": payload
    }
    if redis_client:
        await redis_client.publish(CHANNEL_NAME, json.dumps(event_data))
        logger.info(f"Published event '{event_type}' to channel '{CHANNEL_NAME}'")

@app.post("/api/v1/orders", status_code=status.HTTP_202_ACCEPTED)
async def create_order(order: OrderCreate, background_tasks: BackgroundTasks):
    order_id = f"ord_{int(asyncio.get_event_loop().time() * 1000)}"
    order_data = {
        "order_id": order_id,
        "user_id": order.user_id,
        "item_id": order.item_id,
        "amount": order.amount,
        "status": "created"
    }
    
    # Asynchronously publish event to event bus without blocking request
    background_tasks.add_task(publish_order_event, "ORDER_CREATED", order_data)
    
    return {
        "message": "Order processing initiated",
        "order_id": order_id
    }

```

---

