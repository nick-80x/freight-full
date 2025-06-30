# Docker MCP Server Configuration

## Overview
This configuration sets up the Docker MCP server for the Freight project, enabling container and compose stack management through natural language commands.

## Features
- **Container Management**: Start, stop, restart, and monitor Docker containers
- **Image Operations**: Pull, build, and manage Docker images
- **Compose Stack Management**: Deploy and manage multi-container applications
- **Network Management**: Create and configure Docker networks
- **Volume Management**: Handle persistent data storage
- **Log Analysis**: Stream and analyze container logs

## Setup Instructions

1. **Install the Docker MCP Server**
   ```bash
   npm install -g @modelcontextprotocol/server-docker
   ```

2. **Docker Permission Setup**
   Ensure your user has access to Docker:
   ```bash
   sudo usermod -aG docker $USER
   # Logout and login again for changes to take effect
   ```

3. **Claude Desktop Integration**
   Add this configuration to your Claude Desktop settings:
   ```json
   {
     "mcpServers": {
       "docker": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-docker"],
         "env": {
           "DOCKER_HOST": "unix:///var/run/docker.sock"
         }
       }
     }
   }
   ```

4. **Environment Variables**
   ```bash
   export DOCKER_HOST=unix:///var/run/docker.sock
   export COMPOSE_PROJECT_NAME=freight
   ```

## Freight Container Architecture

### Core Services
```yaml
services:
  # FastAPI Backend
  api:
    image: freight/api:latest
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/freight
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  # Celery Worker
  worker:
    image: freight/worker:latest
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/freight
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  # Celery Flower (Monitoring)
  flower:
    image: freight/flower:latest
    ports:
      - "5555:5555"
    environment:
      - CELERY_BROKER_URL=redis://redis:6379
    depends_on:
      - redis

  # PostgreSQL Database
  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=freight
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  # Redis (Celery Broker)
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## Usage Examples

### Container Management
```
"Show me all running Freight containers"
"Start the freight-worker container"
"Check the logs of the freight-api container from the last 1 hour"
"Restart the Redis container"
"Stop all Freight services gracefully"
```

### Development Operations
```
"Build the Freight API Docker image from the current directory"
"Pull the latest PostgreSQL image"
"Create a new development environment with docker-compose"
"Scale the worker service to 3 replicas"
```

### Monitoring & Debugging
```
"Check the resource usage of all Freight containers"
"Show me error logs from the API container"
"Get the health status of all services"
"Monitor real-time logs from the worker containers"
```

### Network & Volume Management
```
"Create a Docker network for Freight services"
"List all Docker volumes used by Freight"
"Backup the PostgreSQL data volume"
"Connect the API container to the monitoring network"
```

## Common Commands for Freight

### Development Workflow
```bash
# Build and start development environment
docker-compose -f docker-compose.dev.yml up --build

# Scale workers for load testing
docker-compose up --scale worker=5

# View logs for specific service
docker-compose logs -f api

# Execute commands in running containers
docker-compose exec api python manage.py migrate
docker-compose exec worker celery inspect active
```

### Production Deployment
```bash
# Deploy to production
docker-compose -f docker-compose.prod.yml up -d

# Rolling update of API service
docker-compose up -d --no-deps api

# Health check all services
docker-compose ps
```

### Maintenance Operations
```bash
# Backup database
docker-compose exec db pg_dump -U postgres databridge > backup.sql

# Clean up unused resources
docker system prune -f
docker volume prune -f

# Monitor resource usage
docker stats
```

## Security Considerations

### Container Security
- **Non-root Users**: Run containers with non-root users
- **Resource Limits**: Set memory and CPU limits for containers
- **Network Isolation**: Use custom networks for service communication
- **Secret Management**: Use Docker secrets for sensitive data
- **Image Scanning**: Regular vulnerability scans of base images

### Environment-Specific Configurations
```bash
# Development
export DOCKER_ENV=development
export LOG_LEVEL=debug

# Production
export DOCKER_ENV=production
export LOG_LEVEL=info
export ENABLE_HTTPS=true
```

## Monitoring Integration

### Health Checks
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### Metrics Collection
```yaml
# Prometheus monitoring
prometheus:
  image: prom/prometheus
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml

# Grafana dashboards
grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
```

## Troubleshooting

### Common Issues
1. **Port Conflicts**: Check if ports are already in use
2. **Permission Denied**: Ensure Docker socket permissions
3. **Out of Memory**: Monitor container resource usage
4. **Network Issues**: Verify Docker network configuration
5. **Volume Mounting**: Check file permissions and paths

### Debug Commands
```bash
# Check Docker daemon status
docker info

# Inspect container configuration
docker inspect <container_name>

# View Docker events
docker events

# Check container processes
docker top <container_name>
```

## Performance Optimization

### Resource Management
- Set appropriate memory and CPU limits
- Use multi-stage builds to reduce image size
- Implement proper caching strategies
- Monitor container performance metrics

### Scaling Strategies
- Horizontal scaling with Docker Swarm or Kubernetes
- Load balancing across worker containers
- Database connection pooling
- Redis clustering for high availability

This Docker MCP server integration provides comprehensive container management capabilities for the DataBridge platform, enabling AI-assisted DevOps operations and infrastructure management.