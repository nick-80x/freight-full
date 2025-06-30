"""Test configuration and fixtures."""

import pytest
from fastapi.testclient import TestClient

from freight.api.main import app


@pytest.fixture
def client() -> TestClient:  # type: ignore[misc]
    """Create a test client for the FastAPI application."""
    return TestClient(app)
