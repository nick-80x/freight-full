"""Celery worker application."""

from celery import Celery

from freight.core.config import settings

# Create Celery instance
celery_app = Celery(
    "freight",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=["freight.worker.tasks"],
)

# Configure Celery
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    worker_prefetch_multiplier=1,
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    worker_max_tasks_per_child=1000,
    task_time_limit=3600,  # 1 hour
    task_soft_time_limit=3000,  # 50 minutes
)

# Queue configuration
celery_app.conf.task_routes = {
    "freight.worker.tasks.process_migration_batch": {"queue": "default"},
    "freight.worker.tasks.retry_failed_batch": {"queue": "high_priority"},
}
