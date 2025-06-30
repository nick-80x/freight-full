"""Application configuration."""

from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", case_sensitive=False, extra="ignore"
    )

    # Application
    app_name: str = "Freight"
    version: str = "0.1.0"
    debug: bool = False
    environment: str = "development"

    # Security
    secret_key: str = Field(..., description="Secret key for JWT encoding")

    # Database
    database_url: str = Field(..., description="PostgreSQL database URL")

    # Redis
    redis_url: str = Field(
        default="redis://localhost:6379/0", description="Redis connection URL"
    )

    # Celery
    celery_broker_url: str = Field(
        default="redis://localhost:6379/0", description="Celery broker URL"
    )
    celery_result_backend: str = Field(
        default="redis://localhost:6379/1", description="Celery result backend URL"
    )

    # API
    api_v1_prefix: str = "/api/v1"
    allowed_hosts: list[str] = ["*"]

    # External APIs
    github_personal_access_token: Optional[str] = None
    railway_token: Optional[str] = None


settings = Settings()
