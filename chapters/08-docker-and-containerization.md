# Chapter 08: Docker and Containerization

Containerization package applications with their entire runtime environment—code, dependencies, system libraries, and configurations—ensuring consistent execution across development, staging, and production.

---

## 1. Containers vs. Virtual Machines

Unlike traditional Virtual Machines that require a full guest operating system, containers leverage Linux kernel namespaces and control groups (cgroups) to share the host kernel while maintaining process isolation.

```
┌─────────────────────────────┐        ┌─────────────────────────────┐
│  App A   │  App B   │ App C │        │  App A   │  App B   │ App C │
├──────────┼──────────┼───────┤        ├──────────┼──────────┼───────┤
│ Bins/Libs│ Bins/Libs│Bins/Lib        │ Bins/Libs│ Bins/Libs│Bins/Lib
├──────────┼──────────┼───────┤        ├──────────┼──────────┼───────┤
│ Guest OS │ Guest OS │Guest OS        │   Docker Container Engine   │
├──────────┴──────────┴───────┤        ├─────────────────────────────┤
│          Hypervisor         │        │       Host OS Kernel        │
├─────────────────────────────┤        ├─────────────────────────────┤
│      Physical Infrastructure│        │   Physical Infrastructure   │
└─────────────────────────────┘        └─────────────────────────────┘
      Virtual Machines                       Container Architecture

```

| Dimension | Virtual Machines (VMs) | Docker Containers |
| --- | --- | --- |
| **Isolation** | Hardware-level hypervisor | Process-level Linux Kernel namespaces |
| **Startup Time** | Minutes | Milliseconds to seconds |
| **Resource Overhead** | High (Requires dedicated Guest OS RAM/Disk) | Low (Shares host kernel resources) |
| **Image Size** | Multi-gigabyte (GB) | Megabytes (MB) |

---

## 2. Linux Kernel Isolation Primitives

Docker relies on key Linux kernel features to enforce container security and resource limits:

* **Namespaces (Isolation):** Partition kernel resources so processes only see their own environment.
* `pid`: Process tree isolation.
* `net`: Network interfaces and routing tables.
* `mnt`: File system mount points.
* `ipc`: Inter-process communication channels.


* **cgroups / Control Groups (Resource Limits):** Enforce CPU, memory, I/O, and network bandwidth quotas for every running container.
* **OverlayFS (Layered Storage):** Copy-on-write (CoW) file system allowing images to share immutable layers efficiently.

---

## 3. Production Multi-Stage Dockerfile Pattern

Multi-stage builds separate the build-time SDKs and dependencies from the minimal runtime environment, reducing image attack surfaces and total payload size.

```dockerfile
# ==========================================
# Stage 1: Build & Dependency Resolution
# ==========================================
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python requirements to a virtual environment
COPY requirements.txt .
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

# ==========================================
# Stage 2: Minimal Production Runtime
# ==========================================
FROM python:3.12-slim AS runner

WORKDIR /app

# Create a non-root system user for security
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /bin/sh appuser

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application source code
COPY --chown=appuser:appgroup ./app ./app

# Drop root privileges
USER appuser

EXPOSE 8000

# Health check probe
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

```

---

## 4. Multi-Container Orchestration (`docker-compose.yml`)

Docker Compose defines multi-container applications, configuring networking, volumes, environment variables, and startup orders.

```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:secret@postgres:5432/handbook_db
      - ENVIRONMENT=production
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  postgres:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=secret
      - POSTGRES_DB=handbook_db
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pgdata:

```

---