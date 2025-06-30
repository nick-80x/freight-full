# FastAPI MCP Integration for Freight

## Overview
This integration exposes the Freight migration API endpoints as MCP (Model Context Protocol) tools, enabling AI assistants to interact with your migration platform through natural language.

## Features
- **Job Management**: Create, monitor, and control migration jobs
- **Retry Operations**: Intelligent retry mechanisms for failed batches
- **Audit Logging**: Detailed record-level processing logs
- **Multi-tenant Support**: Tenant-isolated operations with proper authentication
- **Statistics & Monitoring**: Real-time insights into migration performance
- **Natural Language Interface**: AI-powered API interaction

## Installation

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Environment Setup**
   ```bash
   export FREIGHT_API_URL="http://localhost:8000"
   export DATABASE_URL="postgresql://user:pass@localhost:5432/freight"
   export REDIS_URL="redis://localhost:6379"
   ```

3. **Run the MCP Server**
   ```bash
   python freight_mcp_server.py
   ```

## Claude Desktop Integration

Add this configuration to your Claude Desktop settings:

```json
{
  "mcpServers": {
    "freight-api": {
      "command": "python",
      "args": ["/path/to/freight_mcp_server.py"],
      "env": {
        "FREIGHT_API_URL": "http://localhost:8000"
      }
    }
  }
}
```

## Available MCP Tools

### Job Management
- `create_migration_job`: Create new migration jobs with source/target configs
- `list_migration_jobs`: List and filter jobs by status
- `get_migration_job`: Get detailed job information
- `retry_migration_job`: Retry failed batches with custom parameters
- `cancel_migration_job`: Cancel running jobs gracefully

### Monitoring & Logs
- `get_migration_logs`: Retrieve detailed processing logs
- `export_migration_logs`: Generate downloadable log exports
- `get_job_statistics`: Job performance and success metrics
- `get_worker_status`: Celery worker health and queue status
- `health_check`: API health monitoring

### Admin Operations
- `get_tenant_statistics`: Platform-wide metrics (admin only)

## Usage Examples

### Natural Language Queries

**Job Creation:**
```
"Create a migration job for tenant 'acme-corp' to migrate users from MySQL to PostgreSQL with batch size 500"
```

**Monitoring:**
```
"Show me all failed migration jobs for tenant 'acme-corp' from the last 24 hours"
"What's the current status of job abc-123-def?"
"How many workers are currently processing jobs?"
```

**Retry Operations:**
```
"Retry all failed batches for job xyz-789 with max 5 retry attempts"
"Retry specific batch IDs batch-001, batch-002 for job abc-123"
```

**Analytics:**
```
"Show me job statistics for tenant 'acme-corp'"
"What's the overall platform success rate?"
"Export logs for job abc-123 as CSV"
```

### API Integration Examples

**Creating a Migration Job:**
```python
# This gets converted to MCP tool automatically
POST /api/v1/jobs
{
    "source_config": {
        "type": "mysql",
        "host": "source.db.com",
        "database": "users_db"
    },
    "target_config": {
        "type": "postgresql", 
        "host": "target.db.com",
        "database": "users_new"
    },
    "batch_size": 1000,
    "started_by": "migration-engineer@acme.com"
}
```

**Monitoring Job Progress:**
```python
# Natural language: "Check status of job abc-123"
GET /api/v1/jobs/abc-123-def
```

**Retry Failed Batches:**
```python
# Natural language: "Retry failed batches for job abc-123"
POST /api/v1/jobs/abc-123/retry
{
    "max_retries": 5
}
```

## Authentication & Security

### Tenant Authentication
All API calls require the `X-Tenant-ID` header for proper tenant isolation:

```python
headers = {
    "X-Tenant-ID": "acme-corp",
    "Authorization": "Bearer your-api-token"
}
```

### Security Features
- **Tenant Isolation**: All operations are scoped to authenticated tenant
- **API Rate Limiting**: Configurable per-tenant rate limits
- **Audit Logging**: Complete audit trail of all operations
- **Role-Based Access**: Different permissions for engineers vs admins

## Configuration

### Environment Variables
```bash
# API Configuration
FREIGHT_API_URL=http://localhost:8000
FREIGHT_API_KEY=your-api-key

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/freight

# Redis/Celery
REDIS_URL=redis://localhost:6379
CELERY_BROKER_URL=redis://localhost:6379
CELERY_RESULT_BACKEND=redis://localhost:6379

# Security
JWT_SECRET_KEY=your-secret-key
TOKEN_EXPIRY_HOURS=24

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090
```

### Development vs Production
- **Development**: Uses SQLite and local Redis for simplicity
- **Production**: Requires PostgreSQL and Redis Cluster for scalability
- **Testing**: Includes comprehensive test suite with mocked dependencies

## Error Handling

The MCP server provides comprehensive error handling with descriptive messages:

- **400 Bad Request**: Invalid input parameters or missing tenant ID
- **401 Unauthorized**: Invalid or missing authentication
- **403 Forbidden**: Insufficient permissions for operation
- **404 Not Found**: Job or resource not found for tenant
- **409 Conflict**: Operation conflicts with current job state
- **500 Internal Server Error**: Server-side processing errors

## Performance Considerations

- **Connection Pooling**: Database connections are pooled for efficiency
- **Async Operations**: All API endpoints are async-compatible
- **Caching**: Redis caching for frequently accessed data
- **Rate Limiting**: Prevents API abuse and ensures fair resource usage
- **Monitoring**: Built-in metrics and health checks

## Future Enhancements

- **WebSocket Support**: Real-time job progress updates
- **Notification Integration**: Slack/email alerts for job completion
- **Advanced Analytics**: ML-powered migration optimization
- **Custom Workflow**: Configurable migration pipelines
- **API Versioning**: Backward-compatible API evolution