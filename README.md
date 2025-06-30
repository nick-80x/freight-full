# Freight

Multi-tenant data migration platform for seamless Affinity to Attio migrations.

## Overview

Freight is a robust, multi-tenant data migration platform designed to facilitate smooth and reliable data transfers between CRM systems, specifically optimized for Affinity to Attio migrations. Built with FastAPI, Celery, and PostgreSQL, it provides enterprise-grade reliability with comprehensive retry mechanisms and detailed logging.

## Features

- **Multi-tenant Architecture**: Secure tenant isolation with API key authentication
- **Reliable Processing**: Built-in retry mechanisms with exponential backoff
- **Batch Processing**: Configurable batch sizes for optimal performance
- **Comprehensive Logging**: Detailed tracking of all migration activities
- **REST API**: Full-featured API for job management and monitoring
- **Real-time Monitoring**: Health checks and performance metrics

## Quick Start

### Prerequisites

- Python 3.12+
- PostgreSQL 15+
- Redis 7+
- Poetry (for dependency management)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/nick-80x/freight-full.git
cd freight-full
```

2. Install dependencies:
```bash
poetry install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run database migrations:
```bash
poetry run alembic upgrade head
```

5. Start the services:
```bash
# Start the API server
poetry run uvicorn freight.api.main:app --reload

# Start the Celery worker (in another terminal)
poetry run celery -A freight.worker worker --loglevel=info
```

## Project Structure

```
freight/
├── api/                    # FastAPI application
├── worker/                 # Celery workers
├── core/                   # Core configuration and utilities
├── models/                 # SQLAlchemy models
├── schemas/                # Pydantic schemas
├── services/               # Business logic
├── middleware/             # Custom middleware
└── dependencies/           # Dependency injection
```

## Development

### Setting up Development Environment

1. Install development dependencies:
```bash
poetry install --with dev
```

2. Set up pre-commit hooks:
```bash
poetry run pre-commit install
```

3. Run tests:
```bash
poetry run pytest
```

4. Run linting and formatting:
```bash
poetry run black freight tests
poetry run isort freight tests
poetry run ruff check freight tests
poetry run mypy freight
```

### Database Migrations

Create a new migration:
```bash
poetry run alembic revision --autogenerate -m "Description of changes"
```

Apply migrations:
```bash
poetry run alembic upgrade head
```

## API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Configuration

Key environment variables:

- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `SECRET_KEY`: Application secret key
- `GITHUB_PERSONAL_ACCESS_TOKEN`: For GitHub integration
- `RAILWAY_TOKEN`: For deployment

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For questions and support, please open an issue on GitHub.
