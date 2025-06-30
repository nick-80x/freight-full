# Multi-stage Dockerfile for Freight API

# Python base image
FROM python:3.12-slim as base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -U freight && \
    mkdir -p /app && \
    chown -R freight:freight /app

WORKDIR /app

# Install Poetry
RUN pip install poetry==2.1.3

# Configure Poetry
RUN poetry config virtualenvs.create false
RUN poetry config virtualenvs.in-project false

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Development stage
FROM base as development

# Install all dependencies (including dev)
RUN poetry install

# Copy source code
COPY --chown=freight:freight . .

USER freight

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

CMD ["uvicorn", "freight.api.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Test stage
FROM development as test

USER root
RUN apt-get update && apt-get install -y \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

USER freight

CMD ["pytest", "-v", "--cov=freight", "--cov-report=term-missing"]

# Production stage
FROM base as production

# Install only production dependencies
RUN poetry install --only=main

# Copy source code
COPY --chown=freight:freight . .

# Pre-compile Python files
RUN python -m compileall -b .

USER freight

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

CMD ["gunicorn", "freight.api.main:app", \
     "--workers", "4", \
     "--worker-class", "uvicorn.workers.UvicornWorker", \
     "--bind", "0.0.0.0:8000", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
