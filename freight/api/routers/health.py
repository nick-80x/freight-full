"""Health check endpoints."""

from datetime import UTC, datetime
from typing import Any, Dict

from fastapi import APIRouter, status

from freight.core.config import settings

router = APIRouter()


@router.get("/", status_code=status.HTTP_200_OK)
async def health_check() -> Dict[str, Any]:  # type: ignore[misc]
    """Basic health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.now(UTC).isoformat(),
        "version": settings.version,
        "environment": settings.environment,
    }


@router.get("/ready", status_code=status.HTTP_200_OK)
async def readiness_check() -> Dict[str, Any]:  # type: ignore[misc]
    """Readiness check for Kubernetes deployments."""
    # TODO: Add checks for database and Redis connectivity
    return {
        "status": "ready",
        "timestamp": datetime.now(UTC).isoformat(),
        "checks": {
            "database": "pending",
            "redis": "pending",
            "celery": "pending",
        },
    }


@router.get("/live", status_code=status.HTTP_200_OK)
async def liveness_check() -> Dict[str, Any]:  # type: ignore[misc]
    """Liveness check for Kubernetes deployments."""
    return {
        "status": "alive",
        "timestamp": datetime.now(UTC).isoformat(),
    }
