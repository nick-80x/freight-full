# Redis MCP Server Configuration

## Overview
This configuration sets up the Redis MCP server for the Freight project, enabling natural language interface for Redis data management and Celery queue monitoring.

## Features
- Celery task queue inspection and monitoring
- Redis key-value operations through natural language
- Task result retrieval and analysis
- Queue length monitoring and statistics
- Dead letter queue management

## Setup Instructions

1. **Install the Redis MCP Server**
   ```bash
   npm install -g @redis/mcp-redis
   ```

2. **Redis Configuration**
   Update the `REDIS_URL` in the config.json file with your actual Redis connection string:
   ```
   redis://username:password@host:port/db_number
   ```

3. **Claude Desktop Integration**
   Add this configuration to your Claude Desktop settings:
   ```json
   {
     "mcpServers": {
       "redis": {
         "command": "npx",
         "args": ["-y", "@redis/mcp-redis"],
         "env": {
           "REDIS_URL": "redis://localhost:6379"
         }
       }
     }
   }
   ```

4. **Environment Variables**
   Set up environment variables for Redis access:
   ```bash
   export REDIS_URL="redis://localhost:6379"
   export REDIS_DB="0"
   ```

## Celery Integration

### Common Celery Keys in Redis
- `celery`: Default queue for tasks
- `celery-task-meta-*`: Task result storage
- `_kombu.binding.*`: Message routing information
- `unacked_mutex`: Unacknowledged tasks tracking

### Queue Monitoring Commands
The MCP server enables natural language queries like:

- "Show me the current Celery queue length"
- "List all pending migration tasks"
- "Get the status of task ID xyz123"
- "Show me failed tasks from the last hour"
- "Clear the dead letter queue"
- "Get queue statistics for all workers"

## Usage Examples

### Task Monitoring
```
"Show me all tasks in the celery queue"
"Get the result for task f47ac10b-58cc-4372-a567-0e02b2c3d479"
"List all failed migration jobs in Redis"
```

### Queue Management
```
"How many tasks are currently pending?"
"Show me the worker heartbeat information"
"Get statistics for the migration queue"
```

### Data Analysis
```
"Find all keys related to tenant 'acme-corp'"
"Show me the retry count for failed tasks"
"Get the average task execution time from Redis"
```

## Security Considerations

- Configure Redis with authentication in production
- Use separate Redis databases for different environments
- Implement proper key expiration policies
- Monitor Redis memory usage for large task queues
- Set up Redis Sentinel for high availability

## Celery Configuration Reference

### Task States
- `PENDING`: Task is waiting for execution
- `STARTED`: Task has been started
- `SUCCESS`: Task executed successfully
- `FAILURE`: Task failed with exception
- `RETRY`: Task is being retried
- `REVOKED`: Task was revoked/cancelled

### Key Patterns
- `celery-task-meta-{task_id}`: Individual task metadata
- `_kombu.binding.{queue}`: Queue binding information
- `celery`: Default task queue
- `{tenant_id}:migration:*`: Tenant-specific migration tasks

## Monitoring and Alerting

Set up alerts for:
- Queue length exceeding thresholds
- Failed task rate above normal
- Worker heartbeat failures
- Memory usage warnings
- Task execution time anomalies