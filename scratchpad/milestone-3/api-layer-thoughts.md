# Milestone 3: API Layer Thoughts

## Overview
Design decisions and implementation notes for the RESTful API layer using FastAPI.

## API Design Principles

### RESTful Standards
- Use proper HTTP methods (GET, POST, PUT, DELETE)
- Meaningful resource URLs (/api/v1/jobs, not /api/v1/getJobs)
- Proper status codes (201 for created, 404 for not found)
- Consistent error response format
- HATEOAS where it makes sense (links to related resources)

### Versioning Strategy
```
URL Path Versioning: /api/v1/...
Why: Simple, explicit, easy to deprecate old versions

Headers Alternative (considered but rejected):
Accept: application/vnd.freight.v1+json
Reason: More complex for clients to implement
```

## FastAPI Project Structure

```
api/
├── __init__.py
├── main.py              # FastAPI app initialization
├── core/
│   ├── config.py       # Settings with Pydantic
│   ├── security.py     # Authentication/authorization
│   ├── database.py     # Database connection
│   └── exceptions.py   # Custom exceptions
├── models/
│   ├── tenant.py       # SQLAlchemy models
│   ├── job.py
│   └── log.py
├── schemas/
│   ├── tenant.py       # Pydantic schemas
│   ├── job.py
│   └── log.py
├── routers/
│   ├── jobs.py         # Job management endpoints
│   ├── logs.py         # Log retrieval endpoints
│   ├── retry.py        # Retry control endpoints
│   ├── health.py       # Health/monitoring endpoints
│   └── stats.py        # Statistics endpoints
├── services/
│   ├── job_service.py  # Business logic
│   ├── retry_service.py
│   └── stats_service.py
├── middleware/
│   ├── tenant.py       # Tenant context injection
│   ├── logging.py      # Request/response logging
│   └── errors.py       # Global error handling
└── dependencies/
    ├── auth.py         # Authentication dependencies
    ├── database.py     # Database session
    └── pagination.py   # Pagination helpers
```

## Authentication & Authorization

### API Key Authentication
```python
from fastapi import Security, HTTPException, status
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def verify_api_key(api_key: str = Security(api_key_header)) -> Tenant:
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required"
        )
    
    # Extract key prefix for faster lookup
    if not api_key.startswith("frt_"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key format"
        )
    
    # Look up tenant by key prefix
    tenant = await get_tenant_by_key_prefix(api_key[:12])
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key"
        )
    
    # Verify full key
    if not verify_api_key_hash(api_key, tenant.api_key_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key"
        )
    
    return tenant
```

### Tenant Context Middleware
```python
from starlette.middleware.base import BaseHTTPMiddleware

class TenantContextMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        # Extract tenant from request state (set by auth dependency)
        tenant = getattr(request.state, "tenant", None)
        
        if tenant:
            # Set tenant context for database queries
            set_current_tenant(tenant.id)
            
            # Add tenant info to request headers for logging
            request.state.tenant_id = tenant.id
            request.state.tenant_slug = tenant.slug
        
        response = await call_next(request)
        
        # Clear tenant context
        clear_current_tenant()
        
        return response
```

## Request/Response Schemas

### Job Creation Request
```python
from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any
from datetime import datetime

class JobCreateRequest(BaseModel):
    source_system: str = Field(..., example="affinity")
    target_system: str = Field(..., example="attio")
    source_config: Dict[str, Any] = Field(..., example={
        "api_key": "aff_key_xxx",
        "base_url": "https://api.affinity.co"
    })
    target_config: Dict[str, Any] = Field(..., example={
        "api_key": "attio_key_xxx",
        "workspace_id": "ws_xxx"
    })
    batch_size: Optional[int] = Field(1000, ge=100, le=10000)
    retry_policy: Optional[RetryPolicySchema] = None
    
    @validator('source_system')
    def validate_source_system(cls, v):
        allowed = ['affinity']
        if v not in allowed:
            raise ValueError(f"Source system must be one of {allowed}")
        return v
    
    @validator('target_system')
    def validate_target_system(cls, v):
        allowed = ['attio']
        if v not in allowed:
            raise ValueError(f"Target system must be one of {allowed}")
        return v

class JobResponse(BaseModel):
    id: str
    status: str
    source_system: str
    target_system: str
    total_records: int
    processed_records: int
    failed_records: int
    created_at: datetime
    updated_at: datetime
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    
    class Config:
        from_attributes = True
```

### Error Response Format
```python
class ErrorDetail(BaseModel):
    type: str
    message: str
    field: Optional[str] = None

class ErrorResponse(BaseModel):
    error: str
    message: str
    details: Optional[List[ErrorDetail]] = None
    request_id: str
    timestamp: datetime
    
# Example usage
{
    "error": "validation_error",
    "message": "Invalid request parameters",
    "details": [
        {
            "type": "value_error",
            "message": "Batch size must be between 100 and 10000",
            "field": "batch_size"
        }
    ],
    "request_id": "req_a1b2c3d4",
    "timestamp": "2024-01-15T10:30:00Z"
}
```

## API Endpoints Implementation

### Job Management
```python
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from uuid import UUID

router = APIRouter(prefix="/api/v1/jobs", tags=["jobs"])

@router.post("", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
async def create_job(
    job_data: JobCreateRequest,
    tenant: Tenant = Depends(verify_api_key),
    db: Session = Depends(get_db)
) -> JobResponse:
    """Create a new migration job."""
    
    # Validate source/target credentials
    try:
        validate_source_credentials(job_data.source_config)
        validate_target_credentials(job_data.target_config)
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid credentials: {str(e)}"
        )
    
    # Create job in database
    job = await job_service.create_job(
        tenant_id=tenant.id,
        job_data=job_data,
        started_by=tenant.name
    )
    
    # Queue job for processing
    await queue_job_for_processing(job.id)
    
    return JobResponse.from_orm(job)

@router.get("/{job_id}", response_model=JobResponse)
async def get_job(
    job_id: UUID,
    tenant: Tenant = Depends(verify_api_key),
    db: Session = Depends(get_db)
) -> JobResponse:
    """Get job details by ID."""
    
    job = await job_service.get_job(
        tenant_id=tenant.id,
        job_id=job_id
    )
    
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job {job_id} not found"
        )
    
    return JobResponse.from_orm(job)

@router.get("", response_model=List[JobResponse])
async def list_jobs(
    status: Optional[str] = None,
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    tenant: Tenant = Depends(verify_api_key),
    db: Session = Depends(get_db)
) -> List[JobResponse]:
    """List jobs for the tenant with optional filtering."""
    
    jobs = await job_service.list_jobs(
        tenant_id=tenant.id,
        status=status,
        limit=limit,
        offset=offset
    )
    
    return [JobResponse.from_orm(job) for job in jobs]
```

### Retry Control
```python
@router.post("/api/v1/jobs/{job_id}/retry")
async def retry_job(
    job_id: UUID,
    retry_failed_only: bool = True,
    tenant: Tenant = Depends(verify_api_key),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Retry a job or its failed batches."""
    
    job = await job_service.get_job(tenant.id, job_id)
    if not job:
        raise HTTPException(404, "Job not found")
    
    if job.status not in ["failed", "completed_with_errors"]:
        raise HTTPException(
            400, 
            f"Cannot retry job in status: {job.status}"
        )
    
    retry_count = await retry_service.retry_job(
        job_id=job_id,
        retry_failed_only=retry_failed_only
    )
    
    return {
        "job_id": str(job_id),
        "batches_queued_for_retry": retry_count,
        "message": f"Queued {retry_count} batches for retry"
    }
```

## Pagination Implementation

```python
from typing import Generic, TypeVar, Optional
from pydantic import BaseModel

T = TypeVar('T')

class PaginationParams(BaseModel):
    limit: int = Field(100, ge=1, le=1000)
    offset: int = Field(0, ge=0)
    
class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    limit: int
    offset: int
    has_more: bool
    
    @property
    def pages(self) -> int:
        return math.ceil(self.total / self.limit)
    
    @property
    def current_page(self) -> int:
        return math.floor(self.offset / self.limit) + 1

# Usage in endpoint
@router.get("", response_model=PaginatedResponse[JobResponse])
async def list_jobs_paginated(
    pagination: PaginationParams = Depends(),
    tenant: Tenant = Depends(verify_api_key)
) -> PaginatedResponse[JobResponse]:
    
    jobs, total = await job_service.list_jobs_with_count(
        tenant_id=tenant.id,
        limit=pagination.limit,
        offset=pagination.offset
    )
    
    return PaginatedResponse(
        items=[JobResponse.from_orm(job) for job in jobs],
        total=total,
        limit=pagination.limit,
        offset=pagination.offset,
        has_more=(pagination.offset + pagination.limit) < total
    )
```

## Rate Limiting

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

# Create limiter instance
limiter = Limiter(
    key_func=lambda request: request.state.tenant_id,  # Rate limit by tenant
    default_limits=["1000/hour", "100/minute"]
)

# Add to FastAPI app
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Apply to endpoints
@router.post("")
@limiter.limit("10/minute")  # Job creation limit
async def create_job(...):
    pass

@router.get("")
@limiter.limit("100/minute")  # Read operations higher limit
async def list_jobs(...):
    pass
```

## Global Error Handling

```python
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(ValidationError)
async def validation_exception_handler(request: Request, exc: ValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "error": "validation_error",
            "message": "Invalid request data",
            "details": exc.errors(),
            "request_id": request.state.request_id,
            "timestamp": datetime.utcnow().isoformat()
        }
    )

@app.exception_handler(TenantNotFoundError)
async def tenant_exception_handler(request: Request, exc: TenantNotFoundError):
    return JSONResponse(
        status_code=404,
        content={
            "error": "tenant_not_found",
            "message": str(exc),
            "request_id": request.state.request_id,
            "timestamp": datetime.utcnow().isoformat()
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    # Log the full exception
    logger.error(
        "Unhandled exception",
        exc_info=exc,
        request_id=request.state.request_id,
        path=request.url.path
    )
    
    return JSONResponse(
        status_code=500,
        content={
            "error": "internal_server_error",
            "message": "An unexpected error occurred",
            "request_id": request.state.request_id,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
```

## Request/Response Logging

```python
import time
import json
from starlette.middleware.base import BaseHTTPMiddleware

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        # Generate request ID
        request_id = f"req_{uuid4().hex[:8]}"
        request.state.request_id = request_id
        
        # Log request
        start_time = time.time()
        
        logger.info("request_started",
            request_id=request_id,
            method=request.method,
            path=request.url.path,
            tenant_id=getattr(request.state, "tenant_id", None)
        )
        
        # Process request
        response = await call_next(request)
        
        # Calculate duration
        duration = time.time() - start_time
        
        # Log response
        logger.info("request_completed",
            request_id=request_id,
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=int(duration * 1000),
            tenant_id=getattr(request.state, "tenant_id", None)
        )
        
        # Add request ID to response headers
        response.headers["X-Request-ID"] = request_id
        
        return response
```

## OpenAPI Documentation

```python
from fastapi import FastAPI

app = FastAPI(
    title="Freight Migration API",
    description="Multi-tenant data migration platform",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    servers=[
        {"url": "https://api.freight.com", "description": "Production"},
        {"url": "https://staging-api.freight.com", "description": "Staging"},
        {"url": "http://localhost:8000", "description": "Development"}
    ]
)

# Custom OpenAPI schema
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
        
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    
    # Add security scheme
    openapi_schema["components"]["securitySchemes"] = {
        "apiKey": {
            "type": "apiKey",
            "in": "header",
            "name": "X-API-Key"
        }
    }
    
    # Apply security to all endpoints
    for path in openapi_schema["paths"].values():
        for operation in path.values():
            operation["security"] = [{"apiKey": []}]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi
```

## Health Check Implementation

```python
from enum import Enum

class HealthStatus(str, Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"

@router.get("/health", tags=["monitoring"])
async def health_check() -> Dict[str, Any]:
    """Comprehensive health check endpoint."""
    
    checks = {
        "database": await check_database_health(),
        "redis": await check_redis_health(),
        "celery": await check_celery_health(),
    }
    
    # Determine overall status
    if all(check["status"] == "healthy" for check in checks.values()):
        overall_status = HealthStatus.HEALTHY
    elif any(check["status"] == "unhealthy" for check in checks.values()):
        overall_status = HealthStatus.UNHEALTHY
    else:
        overall_status = HealthStatus.DEGRADED
    
    return {
        "status": overall_status,
        "timestamp": datetime.utcnow().isoformat(),
        "version": app.version,
        "checks": checks
    }

async def check_database_health() -> Dict[str, Any]:
    try:
        # Execute simple query
        result = await db.execute("SELECT 1")
        return {"status": "healthy", "response_time_ms": 5}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

## Performance Optimizations

### Response Caching
```python
from fastapi_cache import FastAPICache
from fastapi_cache.decorator import cache
from fastapi_cache.backends.redis import RedisBackend

# Initialize cache
@app.on_event("startup")
async def startup():
    redis = aioredis.from_url("redis://localhost", encoding="utf8")
    FastAPICache.init(RedisBackend(redis), prefix="freight-cache:")

# Cache job list for tenant
@router.get("", response_model=List[JobResponse])
@cache(expire=60)  # Cache for 60 seconds
async def list_jobs(
    tenant: Tenant = Depends(verify_api_key),
    status: Optional[str] = None
) -> List[JobResponse]:
    # Cache key includes tenant_id automatically
    pass
```

### Database Query Optimization
```python
# Use select_related for foreign keys
jobs = await db.query(Job).options(
    selectinload(Job.batches),
    selectinload(Job.logs)
).filter(
    Job.tenant_id == tenant_id
).limit(limit).offset(offset).all()

# Use indexes effectively
# Always filter by tenant_id first (composite index)
```

## Testing API Endpoints

```python
from fastapi.testclient import TestClient
import pytest

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture
def api_key():
    return "frt_test_abcd1234efgh5678"

def test_create_job(client, api_key):
    response = client.post(
        "/api/v1/jobs",
        headers={"X-API-Key": api_key},
        json={
            "source_system": "affinity",
            "target_system": "attio",
            "source_config": {...},
            "target_config": {...}
        }
    )
    
    assert response.status_code == 201
    assert response.json()["status"] == "pending"
    
def test_unauthorized_request(client):
    response = client.get("/api/v1/jobs")
    assert response.status_code == 401
    assert response.json()["detail"] == "API key required"
```

## Deployment Considerations

### CORS Configuration
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://app.freight.com"],  # Frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID", "X-RateLimit-Remaining"]
)
```

### Production Settings
```python
class Settings(BaseSettings):
    api_v1_prefix: str = "/api/v1"
    debug: bool = False
    
    # Security
    api_key_min_length: int = 32
    allowed_hosts: List[str] = ["api.freight.com", "*.freight.com"]
    
    # Rate limiting
    rate_limit_default: str = "1000/hour"
    rate_limit_job_creation: str = "100/hour"
    
    # Performance
    db_pool_size: int = 20
    db_max_overflow: int = 40
    redis_pool_size: int = 50
    
    class Config:
        env_file = ".env"
```

## Next Steps

1. Implement authentication system with API keys
2. Create all CRUD endpoints for jobs
3. Add comprehensive error handling
4. Set up request/response logging
5. Configure rate limiting
6. Write API integration tests