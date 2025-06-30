# Milestone 4: MVP Completion Thoughts

## Overview
Planning notes for production deployment, monitoring, and performance validation.

## Integration Testing Strategy

### Test Environment Setup
```yaml
# docker-compose.test.yml
version: '3.8'

services:
  test-db:
    image: postgres:15
    environment:
      POSTGRES_DB: freight_test
      POSTGRES_USER: freight
      POSTGRES_PASSWORD: testpass
    tmpfs:
      - /var/lib/postgresql/data  # In-memory for speed

  test-redis:
    image: redis:7-alpine
    command: redis-server --save ""  # Disable persistence

  test-api:
    build: 
      context: .
      target: test
    environment:
      DATABASE_URL: postgresql://freight:testpass@test-db:5432/freight_test
      REDIS_URL: redis://test-redis:6379
      TESTING: "true"
    depends_on:
      - test-db
      - test-redis
    command: pytest -v --cov=freight --cov-report=xml

  test-worker:
    build:
      context: .
      target: worker
    environment:
      DATABASE_URL: postgresql://freight:testpass@test-db:5432/freight_test
      REDIS_URL: redis://test-redis:6379
      TESTING: "true"
    depends_on:
      - test-db
      - test-redis
```

### End-to-End Test Scenarios

```python
# tests/e2e/test_full_migration_flow.py
import pytest
from httpx import AsyncClient
import asyncio

@pytest.mark.e2e
async def test_complete_migration_flow():
    """Test full migration lifecycle from job creation to completion."""
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        # 1. Create tenant and get API key
        tenant = await create_test_tenant()
        headers = {"X-API-Key": tenant.api_key}
        
        # 2. Create migration job
        response = await client.post(
            "/api/v1/jobs",
            headers=headers,
            json={
                "source_system": "affinity",
                "target_system": "attio",
                "source_config": {"api_key": "test_key"},
                "target_config": {"api_key": "test_key"},
                "batch_size": 100
            }
        )
        assert response.status_code == 201
        job_id = response.json()["id"]
        
        # 3. Wait for job to start processing
        await wait_for_job_status(client, headers, job_id, "processing", timeout=30)
        
        # 4. Simulate some failures
        await simulate_batch_failures(job_id, failure_rate=0.1)
        
        # 5. Check job completes with errors
        await wait_for_job_status(client, headers, job_id, "completed_with_errors", timeout=60)
        
        # 6. Get job details
        response = await client.get(f"/api/v1/jobs/{job_id}", headers=headers)
        job = response.json()
        assert job["failed_records"] > 0
        
        # 7. Retry failed records
        response = await client.post(
            f"/api/v1/jobs/{job_id}/retry",
            headers=headers,
            json={"retry_failed_only": True}
        )
        assert response.status_code == 200
        
        # 8. Wait for retry completion
        await wait_for_job_status(client, headers, job_id, "completed", timeout=60)
        
        # 9. Verify all records processed
        response = await client.get(f"/api/v1/jobs/{job_id}", headers=headers)
        job = response.json()
        assert job["failed_records"] == 0
        assert job["processed_records"] == job["total_records"]
```

### Load Testing

```python
# tests/load/test_concurrent_jobs.py
import asyncio
from locust import HttpUser, task, between

class MigrationUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Create tenant and get API key."""
        response = self.client.post("/internal/test/create-tenant")
        self.api_key = response.json()["api_key"]
        self.headers = {"X-API-Key": self.api_key}
    
    @task(weight=1)
    def create_job(self):
        """Create a new migration job."""
        response = self.client.post(
            "/api/v1/jobs",
            headers=self.headers,
            json={
                "source_system": "affinity",
                "target_system": "attio",
                "source_config": {"api_key": "test"},
                "target_config": {"api_key": "test"},
                "batch_size": 1000
            }
        )
        
        if response.status_code == 201:
            self.created_job_ids.append(response.json()["id"])
    
    @task(weight=5)
    def check_job_status(self):
        """Check status of existing jobs."""
        if self.created_job_ids:
            job_id = random.choice(self.created_job_ids)
            self.client.get(
                f"/api/v1/jobs/{job_id}",
                headers=self.headers
            )
    
    @task(weight=2)
    def list_jobs(self):
        """List all jobs for tenant."""
        self.client.get(
            "/api/v1/jobs",
            headers=self.headers
        )

# Run with: locust -f test_concurrent_jobs.py --host=http://localhost:8000 --users=50 --spawn-rate=5
```

## Containerization Strategy

### Multi-Stage Dockerfile for API

```dockerfile
# Dockerfile
FROM python:3.11-slim as base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -U freight && \
    mkdir -p /app && \
    chown -R freight:freight /app

WORKDIR /app

# Install Python dependencies
FROM base as dependencies

COPY pyproject.toml poetry.lock ./
RUN pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev --no-root

# Development stage
FROM dependencies as development

RUN poetry install --no-root
COPY . .
RUN poetry install

USER freight
CMD ["uvicorn", "freight.api.main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]

# Test stage
FROM development as test

USER root
RUN apt-get update && apt-get install -y \
    curl \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

USER freight
CMD ["pytest", "-v", "--cov=freight"]

# Production stage
FROM dependencies as production

COPY --chown=freight:freight . .
RUN poetry install --no-dev

# Pre-compile Python files
RUN python -m compileall -b .

USER freight

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["gunicorn", "freight.api.main:app", \
     "--workers", "4", \
     "--worker-class", "uvicorn.workers.UvicornWorker", \
     "--bind", "0.0.0.0:8000", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
```

### Worker Dockerfile

```dockerfile
# Dockerfile.worker
FROM python:3.11-slim as base

RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -U freight && \
    mkdir -p /app && \
    chown -R freight:freight /app

WORKDIR /app

# Install dependencies
COPY pyproject.toml poetry.lock ./
RUN pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev --no-root

# Copy application
COPY --chown=freight:freight . .
RUN poetry install --no-dev

USER freight

# Different commands for different worker types
CMD ["celery", "-A", "freight.worker", "worker", \
     "--loglevel=info", \
     "--concurrency=4", \
     "--queues=default,high_priority"]
```

### Docker Compose for Local Development

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: freight_dev
      POSTGRES_USER: freight
      POSTGRES_PASSWORD: freight_dev_pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U freight"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  api:
    build:
      context: .
      target: development
    environment:
      DATABASE_URL: postgresql://freight:freight_dev_pass@db:5432/freight_dev
      REDIS_URL: redis://redis:6379
      DEBUG: "true"
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: uvicorn freight.api.main:app --reload --host 0.0.0.0 --port 8000

  worker-default:
    build:
      context: .
      dockerfile: Dockerfile.worker
    environment:
      DATABASE_URL: postgresql://freight:freight_dev_pass@db:5432/freight_dev
      REDIS_URL: redis://redis:6379
    volumes:
      - .:/app
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: celery -A freight.worker worker --loglevel=info -Q default

  worker-high-priority:
    build:
      context: .
      dockerfile: Dockerfile.worker
    environment:
      DATABASE_URL: postgresql://freight:freight_dev_pass@db:5432/freight_dev
      REDIS_URL: redis://redis:6379
    volumes:
      - .:/app
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: celery -A freight.worker worker --loglevel=info -Q high_priority --concurrency=2

  flower:
    build:
      context: .
      dockerfile: Dockerfile.worker
    environment:
      CELERY_BROKER_URL: redis://redis:6379
    ports:
      - "5555:5555"
    depends_on:
      - redis
    command: celery -A freight.worker flower --port=5555

volumes:
  postgres_data:
  redis_data:
```

## Monitoring Setup

### Application Metrics with Prometheus

```python
# freight/api/monitoring.py
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi import Response
import time

# Define metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

active_jobs = Gauge(
    'freight_active_jobs',
    'Number of active migration jobs',
    ['tenant_id']
)

records_processed_total = Counter(
    'freight_records_processed_total',
    'Total records processed',
    ['tenant_id', 'status']
)

celery_task_duration_seconds = Histogram(
    'celery_task_duration_seconds',
    'Celery task execution time',
    ['task_name', 'queue']
)

# Middleware to collect metrics
class MetricsMiddleware:
    async def __call__(self, request, call_next):
        start_time = time.time()
        
        # Process request
        response = await call_next(request)
        
        # Record metrics
        duration = time.time() - start_time
        http_requests_total.labels(
            method=request.method,
            endpoint=request.url.path,
            status=response.status_code
        ).inc()
        
        http_request_duration_seconds.labels(
            method=request.method,
            endpoint=request.url.path
        ).observe(duration)
        
        return response

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    return Response(
        content=generate_latest(),
        media_type="text/plain"
    )
```

### Logging Configuration

```python
# freight/core/logging.py
import logging
import structlog
from pythonjsonlogger import jsonlogger

def setup_logging(log_level: str = "INFO"):
    """Configure structured JSON logging."""
    
    # Configure Python logging
    logHandler = logging.StreamHandler()
    formatter = jsonlogger.JsonFormatter(
        fmt="%(asctime)s %(name)s %(levelname)s %(message)s",
        rename_fields={
            "asctime": "timestamp",
            "name": "logger",
            "levelname": "level"
        }
    )
    logHandler.setFormatter(formatter)
    
    logging.root.setLevel(log_level)
    logging.root.handlers = [logHandler]
    
    # Configure structlog
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            add_app_context,  # Custom processor
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

def add_app_context(logger, method_name, event_dict):
    """Add application context to all logs."""
    # Add environment
    event_dict["environment"] = os.getenv("ENVIRONMENT", "development")
    
    # Add version
    event_dict["version"] = os.getenv("APP_VERSION", "unknown")
    
    # Add hostname
    event_dict["hostname"] = socket.gethostname()
    
    # Add request context if available
    if hasattr(_request_context, "request_id"):
        event_dict["request_id"] = _request_context.request_id
        event_dict["tenant_id"] = _request_context.tenant_id
    
    return event_dict
```

### Health Check Implementation

```python
# freight/api/health.py
from typing import Dict, Any
import asyncio
import aioredis
from sqlalchemy import text

async def comprehensive_health_check() -> Dict[str, Any]:
    """Perform comprehensive system health check."""
    
    checks = await asyncio.gather(
        check_database(),
        check_redis(),
        check_celery_workers(),
        check_disk_space(),
        check_memory_usage(),
        return_exceptions=True
    )
    
    health_status = {
        "database": checks[0] if not isinstance(checks[0], Exception) else {"status": "unhealthy", "error": str(checks[0])},
        "redis": checks[1] if not isinstance(checks[1], Exception) else {"status": "unhealthy", "error": str(checks[1])},
        "celery": checks[2] if not isinstance(checks[2], Exception) else {"status": "unhealthy", "error": str(checks[2])},
        "disk": checks[3] if not isinstance(checks[3], Exception) else {"status": "unhealthy", "error": str(checks[3])},
        "memory": checks[4] if not isinstance(checks[4], Exception) else {"status": "unhealthy", "error": str(checks[4])},
    }
    
    # Determine overall status
    statuses = [check.get("status", "unhealthy") for check in health_status.values()]
    if all(status == "healthy" for status in statuses):
        overall_status = "healthy"
    elif any(status == "unhealthy" for status in statuses):
        overall_status = "unhealthy"
    else:
        overall_status = "degraded"
    
    return {
        "status": overall_status,
        "timestamp": datetime.utcnow().isoformat(),
        "version": APP_VERSION,
        "checks": health_status
    }

async def check_celery_workers() -> Dict[str, Any]:
    """Check Celery worker status."""
    try:
        # Get active workers
        inspector = celery_app.control.inspect()
        stats = inspector.stats()
        
        if not stats:
            return {"status": "unhealthy", "error": "No active workers"}
        
        worker_count = len(stats)
        total_tasks = sum(len(worker.get('pool', {}).get('writes', {})) for worker in stats.values())
        
        return {
            "status": "healthy",
            "worker_count": worker_count,
            "active_tasks": total_tasks
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

## Performance Validation

### Benchmark Tests

```python
# tests/benchmarks/test_throughput.py
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor

async def test_api_throughput():
    """Test API can handle required request rate."""
    
    target_rps = 100  # 100 requests per second
    duration = 60  # 1 minute test
    total_requests = target_rps * duration
    
    async def make_request():
        async with AsyncClient(app=app, base_url="http://test") as client:
            response = await client.get("/api/v1/health")
            return response.status_code == 200
    
    start_time = time.time()
    
    # Execute requests concurrently
    tasks = []
    for i in range(total_requests):
        # Spread requests evenly over the duration
        delay = i / target_rps
        task = asyncio.create_task(
            asyncio.sleep(delay).then(make_request())
        )
        tasks.append(task)
    
    results = await asyncio.gather(*tasks)
    end_time = time.time()
    
    # Calculate metrics
    actual_duration = end_time - start_time
    actual_rps = total_requests / actual_duration
    success_rate = sum(results) / len(results)
    
    print(f"Target RPS: {target_rps}")
    print(f"Actual RPS: {actual_rps:.2f}")
    print(f"Success Rate: {success_rate:.2%}")
    
    assert actual_rps >= target_rps * 0.95  # Allow 5% margin
    assert success_rate >= 0.999  # 99.9% success rate

async def test_worker_throughput():
    """Test workers can process required record rate."""
    
    target_records_per_minute = 10000
    test_duration = 300  # 5 minutes
    
    # Create test job with known record count
    job = await create_test_job(
        record_count=target_records_per_minute * 5
    )
    
    # Start job processing
    await start_job_processing(job.id)
    
    # Monitor progress
    start_time = time.time()
    processed_records = 0
    
    while time.time() - start_time < test_duration:
        await asyncio.sleep(10)  # Check every 10 seconds
        
        job_status = await get_job_status(job.id)
        current_processed = job_status.processed_records
        
        # Calculate rate
        elapsed_minutes = (time.time() - start_time) / 60
        current_rate = current_processed / elapsed_minutes
        
        print(f"Current rate: {current_rate:.0f} records/minute")
        
        if job_status.status == "completed":
            break
    
    # Verify throughput
    final_rate = job_status.processed_records / elapsed_minutes
    assert final_rate >= target_records_per_minute * 0.9  # Allow 10% margin
```

### Tenant Isolation Validation

```python
# tests/security/test_tenant_isolation.py
async def test_tenant_isolation():
    """Verify complete tenant isolation."""
    
    # Create two tenants
    tenant_a = await create_test_tenant("tenant-a")
    tenant_b = await create_test_tenant("tenant-b")
    
    # Create jobs for each tenant
    headers_a = {"X-API-Key": tenant_a.api_key}
    headers_b = {"X-API-Key": tenant_b.api_key}
    
    job_a = await create_job(headers_a)
    job_b = await create_job(headers_b)
    
    # Try to access tenant B's job with tenant A's key
    async with AsyncClient(app=app) as client:
        response = await client.get(
            f"/api/v1/jobs/{job_b.id}",
            headers=headers_a
        )
        assert response.status_code == 404
        
        # Verify tenant A can't see tenant B's jobs in list
        response = await client.get(
            "/api/v1/jobs",
            headers=headers_a
        )
        job_ids = [job["id"] for job in response.json()]
        assert job_b.id not in job_ids
        assert job_a.id in job_ids
        
    # Test database level isolation
    with get_db_session() as db:
        # Set tenant context
        set_current_tenant(tenant_a.id)
        
        # Query should only return tenant A's data
        jobs = db.query(Job).all()
        assert all(job.tenant_id == tenant_a.id for job in jobs)
        assert len(jobs) == 1
```

## Deployment Strategy

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
    
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
          
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install Poetry
        run: |
          curl -sSL https://install.python-poetry.org | python3 -
          echo "$HOME/.local/bin" >> $GITHUB_PATH
          
      - name: Install dependencies
        run: poetry install
        
      - name: Run tests
        run: |
          poetry run pytest -v --cov=freight --cov-report=xml
          poetry run mypy freight
          poetry run ruff check freight
          
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      
    steps:
      - uses: actions/checkout@v3
      
      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Build and push API image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/api:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/api:${{ github.sha }}
          target: production
          
      - name: Build and push Worker image
        uses: docker/build-push-action@v4
        with:
          context: .
          file: Dockerfile.worker
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/worker:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/worker:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Railway
        uses: bervProject/railway-deploy@main
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
        with:
          service: freight-api
          
      - name: Run migrations
        run: |
          railway run --service freight-api alembic upgrade head
          
      - name: Health check
        run: |
          sleep 30
          curl -f https://api.freight.com/health || exit 1
```

### Production Configuration

```python
# freight/core/config.py
from pydantic import BaseSettings, PostgresDsn, RedisDsn
from typing import Optional, List

class ProductionSettings(BaseSettings):
    # Application
    app_name: str = "Freight"
    environment: str = "production"
    debug: bool = False
    
    # Database
    database_url: PostgresDsn
    db_pool_size: int = 50
    db_max_overflow: int = 100
    db_pool_timeout: int = 30
    db_pool_recycle: int = 1800
    
    # Redis
    redis_url: RedisDsn
    redis_pool_size: int = 100
    redis_decode_responses: bool = True
    
    # Celery
    celery_broker_url: str
    celery_result_backend: str
    celery_task_time_limit: int = 3600
    celery_task_soft_time_limit: int = 3000
    celery_worker_max_tasks_per_child: int = 1000
    
    # Security
    secret_key: str
    api_key_min_length: int = 32
    allowed_hosts: List[str] = ["api.freight.com"]
    trusted_hosts: List[str] = ["*.freight.com"]
    
    # Rate limiting
    rate_limit_enabled: bool = True
    rate_limit_default: str = "1000/hour"
    rate_limit_storage_url: str  # Redis URL for rate limit storage
    
    # Monitoring
    sentry_dsn: Optional[str] = None
    datadog_api_key: Optional[str] = None
    
    # Performance
    gunicorn_workers: int = 4
    gunicorn_worker_class: str = "uvicorn.workers.UvicornWorker"
    gunicorn_worker_connections: int = 1000
    gunicorn_max_requests: int = 10000
    gunicorn_max_requests_jitter: int = 1000
    
    class Config:
        env_file = ".env"
        case_sensitive = False
```

### Zero-Downtime Deployment

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

echo "Starting zero-downtime deployment..."

# 1. Build new images
docker build -t freight/api:new .
docker build -t freight/worker:new -f Dockerfile.worker .

# 2. Run database migrations
docker run --rm \
  --env-file .env.production \
  freight/api:new \
  alembic upgrade head

# 3. Start new API containers
docker-compose -f docker-compose.prod.yml up -d --scale api=4 --no-recreate api

# 4. Wait for new containers to be healthy
echo "Waiting for new containers to be healthy..."
sleep 30

# 5. Remove old API containers
docker-compose -f docker-compose.prod.yml rm -f api

# 6. Update workers (they can be restarted)
docker-compose -f docker-compose.prod.yml up -d --force-recreate worker

# 7. Tag new images as latest
docker tag freight/api:new freight/api:latest
docker tag freight/worker:new freight/worker:latest

echo "Deployment complete!"
```

## Monitoring Dashboards

### Grafana Dashboard Configuration

```json
{
  "dashboard": {
    "title": "Freight Migration Platform",
    "panels": [
      {
        "title": "API Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ]
      },
      {
        "title": "API Response Time (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "Active Migration Jobs",
        "targets": [
          {
            "expr": "sum(freight_active_jobs) by (tenant_id)"
          }
        ]
      },
      {
        "title": "Records Processing Rate",
        "targets": [
          {
            "expr": "rate(freight_records_processed_total[5m])",
            "legendFormat": "{{tenant_id}} - {{status}}"
          }
        ]
      },
      {
        "title": "Celery Queue Depth",
        "targets": [
          {
            "expr": "celery_queue_length",
            "legendFormat": "{{queue_name}}"
          }
        ]
      },
      {
        "title": "Worker Task Duration (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(celery_task_duration_seconds_bucket[5m]))",
            "legendFormat": "{{task_name}}"
          }
        ]
      }
    ]
  }
}
```

### Alert Rules

```yaml
# monitoring/alerts.yml
groups:
  - name: freight_alerts
    interval: 30s
    rules:
      - alert: HighAPIErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High API error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} for the last 5 minutes"
          
      - alert: CeleryQueueBacklog
        expr: celery_queue_length > 10000
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Celery queue backlog detected"
          description: "Queue {{ $labels.queue_name }} has {{ $value }} pending tasks"
          
      - alert: DatabaseConnectionPoolExhausted
        expr: pg_stat_database_numbackends / pg_settings_max_connections > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Database connection pool near exhaustion"
          description: "{{ $value | humanizePercentage }} of connections in use"
          
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is {{ $value | humanizePercentage }}"
```

## Performance Optimization Checklist

- [ ] Database indexes created and analyzed
- [ ] Connection pooling configured properly
- [ ] Redis pipeline used for bulk operations
- [ ] Celery prefetch multiplier optimized
- [ ] API response caching implemented
- [ ] Batch sizes tuned for optimal throughput
- [ ] Monitoring dashboards configured
- [ ] Alert rules defined and tested
- [ ] Load testing completed successfully
- [ ] Security audit passed
- [ ] Documentation updated
- [ ] Runbook created for operations

## Next Steps

1. Set up staging environment
2. Perform load testing with production-like data
3. Configure monitoring and alerting
4. Create operational runbooks
5. Plan production rollout strategy