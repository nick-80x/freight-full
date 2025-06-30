"""Tests for Celery worker tasks."""

from typing import Any
from unittest.mock import patch

from freight.worker.tasks import health_check, process_migration_batch


def test_health_check_task() -> None:
    """Test the health check task."""
    result = health_check()
    assert result["status"] == "healthy"
    assert result["worker"] == "operational"


@patch("freight.worker.tasks.process_migration_batch.apply_async")
def test_process_migration_batch_task(mock_apply_async: Any) -> None:
    """Test the process migration batch task."""
    # Test the actual task function
    tenant_id = "tenant-123"
    job_id = "job-456"
    batch_id = "batch-789"
    records = [{"id": 1, "name": "test"}, {"id": 2, "name": "test2"}]

    result = process_migration_batch(
        tenant_id=tenant_id, job_id=job_id, batch_id=batch_id, records=records
    )

    assert result["tenant_id"] == tenant_id
    assert result["job_id"] == job_id
    assert result["batch_id"] == batch_id
    assert result["processed"] == 2
    assert result["failed"] == 0
    assert result["errors"] == []
