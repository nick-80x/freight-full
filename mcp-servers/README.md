# Freight MCP Servers Configuration

## Overview
This directory contains Model Context Protocol (MCP) server configurations for the Freight project. These servers enable AI assistants to interact with your development infrastructure through natural language commands.

## 🚀 Quick Setup

### 1. Prerequisites
- Node.js 18+ for MCP server dependencies
- Python 3.11+ for FastAPI MCP integration
- Docker for containerized services
- PostgreSQL database running
- Redis server running
- GitHub Personal Access Token

### 2. Install MCP Servers
```bash
# Install all required MCP servers
npm install -g @modelcontextprotocol/server-postgres
npm install -g @redis/mcp-redis
npm install -g @modelcontextprotocol/server-docker
npm install -g @modelcontextprotocol/server-github

# Install FastAPI MCP dependencies
cd fastapi-integration
pip install -r requirements.txt
```

### 3. Configure Environment Variables
```bash
# Database Configuration
export DATABASE_URL="postgresql://username:password@localhost:5432/freight_dev"

# Redis Configuration
export REDIS_URL="redis://localhost:6379"

# GitHub Configuration
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"

# API Configuration
export FREIGHT_API_URL="http://localhost:8000"

# Docker Configuration
export DOCKER_HOST="unix:///var/run/docker.sock"
```

### 4. Claude Desktop Integration
Copy the contents of `claude-desktop-config.json` to your Claude Desktop configuration:

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
**Linux:** `~/.config/Claude/claude_desktop_config.json`

## 📊 Available MCP Servers

### 🗄️ PostgreSQL MCP Server
**Purpose:** Database inspection and query operations
**Location:** `./postgresql/`

**Capabilities:**
- Natural language database queries
- Schema inspection for migration tables
- Multi-tenant data access
- Read-only operations for safety

**Example Queries:**
- "Show me all failed migration jobs from the last 24 hours"
- "Count migration logs by status for tenant 'acme-corp'"
- "Display the schema for the MigrationJob table"

### 🔴 Redis MCP Server
**Purpose:** Celery queue monitoring and Redis data management
**Location:** `./redis/`

**Capabilities:**
- Celery task queue inspection
- Redis key-value operations
- Task result analysis
- Queue performance monitoring

**Example Queries:**
- "Show me the current Celery queue length"
- "Get the status of migration task xyz-123"
- "List all failed tasks from the last hour"

### ⚡ FastAPI MCP Integration
**Purpose:** Freight API endpoint exposure
**Location:** `./fastapi-integration/`

**Capabilities:**
- Migration job management
- Retry operations control
- Real-time monitoring
- Audit log access

**Example Commands:**
- "Create a migration job for tenant 'acme-corp' with batch size 500"
- "Retry all failed batches for job abc-123"
- "Show job statistics for the last week"

### 🐳 Docker MCP Server
**Purpose:** Container and infrastructure management
**Location:** `./docker/`

**Capabilities:**
- Container lifecycle management
- Docker Compose operations
- Image building and deployment
- Resource monitoring

**Example Commands:**
- "Start the Freight development environment"
- "Check the logs of the API container"
- "Scale the worker service to 3 replicas"

### 🐙 GitHub MCP Server
**Purpose:** Code repository management
**Location:** `./github/`

**Capabilities:**
- Repository operations
- Pull request management
- Issue tracking
- CI/CD workflow monitoring

**Example Commands:**
- "Create a new branch for the retry enhancement feature"
- "Show me all open pull requests that need review"
- "Create an issue for implementing exponential backoff"

## 🔧 Configuration Management

### Environment-Specific Configs
Create separate configuration files for different environments:

```bash
# Development
cp claude-desktop-config.json claude-desktop-config.dev.json

# Staging
cp claude-desktop-config.json claude-desktop-config.staging.json

# Production
cp claude-desktop-config.json claude-desktop-config.prod.json
```

### Security Configuration
```bash
# Use environment variables for sensitive data
export POSTGRES_PASSWORD="$(cat /path/to/postgres-password)"
export GITHUB_TOKEN="$(cat /path/to/github-token)"
export REDIS_PASSWORD="$(cat /path/to/redis-password)"

# Update configurations to use environment variables
sed -i 's/password/\${POSTGRES_PASSWORD}/g' claude-desktop-config.json
```

## 🧪 Testing MCP Servers

### 1. Test Individual Servers
```bash
# Test PostgreSQL MCP Server
npx @modelcontextprotocol/server-postgres --help

# Test Redis MCP Server
npx @redis/mcp-redis --help

# Test FastAPI MCP Server
python fastapi-integration/freight_mcp_server.py
```

### 2. Validate Configuration
```bash
# Check Claude Desktop configuration
cat ~/.config/Claude/claude_desktop_config.json | jq '.'

# Validate environment variables
env | grep -E "(DATABASE_URL|REDIS_URL|GITHUB_PERSONAL_ACCESS_TOKEN)"
```

### 3. Integration Testing
```bash
# Start all required services
docker-compose up -d postgres redis

# Start Freight API
cd ../api && python main.py

# Test MCP server connectivity
# (This would be done through Claude Desktop interface)
```

## 🚨 Troubleshooting

### Common Issues

#### 1. MCP Server Not Found
```bash
# Reinstall MCP servers
npm uninstall -g @modelcontextprotocol/server-postgres
npm install -g @modelcontextprotocol/server-postgres
```

#### 2. Database Connection Failed
```bash
# Check PostgreSQL status
pg_isready -h localhost -p 5432

# Test connection manually
psql "postgresql://username:password@localhost:5432/freight_dev"
```

#### 3. Redis Connection Issues
```bash
# Check Redis status
redis-cli ping

# Test Redis connection
redis-cli -u redis://localhost:6379 info
```

#### 4. GitHub Authentication Failed
```bash
# Verify token permissions
curl -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
     https://api.github.com/user
```

#### 5. Docker Socket Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

### Debug Mode
Enable debug logging for MCP servers:
```bash
export MCP_DEBUG=true
export LOG_LEVEL=debug
```

## 📈 Performance Monitoring

### MCP Server Metrics
Monitor MCP server performance:
```bash
# Check memory usage
ps aux | grep -E "(postgres|redis|docker|github)"

# Monitor network connections
netstat -an | grep -E "(5432|6379|8000)"

# Check disk usage
df -h
```

### Claude Desktop Integration Monitoring
```bash
# Check Claude Desktop logs
tail -f ~/Library/Logs/Claude/claude_desktop.log  # macOS
tail -f ~/.local/state/Claude/logs/claude_desktop.log  # Linux
```

## 🔄 Updates and Maintenance

### Regular Updates
```bash
# Update MCP servers monthly
npm update -g @modelcontextprotocol/server-postgres
npm update -g @redis/mcp-redis
npm update -g @modelcontextprotocol/server-docker
npm update -g @modelcontextprotocol/server-github

# Update Python dependencies
cd fastapi-integration
pip install -r requirements.txt --upgrade
```

### Backup Configurations
```bash
# Backup current configuration
cp ~/.config/Claude/claude_desktop_config.json \
   ~/.config/Claude/claude_desktop_config.backup.$(date +%Y%m%d)
```

## 🎯 Best Practices

1. **Security**: Use environment variables for sensitive data
2. **Monitoring**: Regularly check MCP server health
3. **Updates**: Keep MCP servers updated for latest features
4. **Testing**: Validate configurations after changes
5. **Documentation**: Document custom MCP server configurations
6. **Backup**: Regular backup of configuration files

## 🆘 Support

For issues with specific MCP servers:
- PostgreSQL MCP: [Official Documentation](https://modelcontextprotocol.io/servers/postgres)
- Redis MCP: [Redis MCP GitHub](https://github.com/redis/mcp-redis)
- Docker MCP: [Docker MCP Documentation](https://modelcontextprotocol.io/servers/docker)
- GitHub MCP: [GitHub MCP Documentation](https://modelcontextprotocol.io/servers/github)

For Freight-specific issues:
- Check the `fastapi-integration/README.md` for API-specific guidance
- Review logs in each MCP server directory
- Test individual components before full integration
