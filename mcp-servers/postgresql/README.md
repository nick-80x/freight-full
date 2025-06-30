# PostgreSQL MCP Server Configuration

## Overview
This configuration sets up the PostgreSQL MCP server for the Freight project, enabling natural language database queries and schema inspection.

## Features
- Schema inspection for Tenant, MigrationJob, and MigrationLog tables
- Read-only query execution for data analysis
- Natural language interface for database operations
- Multi-tenant data access with proper isolation

## Setup Instructions

1. **Install the PostgreSQL MCP Server**
   ```bash
   npm install -g @modelcontextprotocol/server-postgres
   ```

2. **Database Configuration**
   Update the `DATABASE_URL` in the config.json file with your actual PostgreSQL connection string:
   ```
   postgresql://username:password@host:port/database_name
   ```

3. **Claude Desktop Integration**
   Add this configuration to your Claude Desktop settings:
   ```json
   {
     "mcpServers": {
       "postgres": {
         "command": "npx",
         "args": [
           "-y", 
           "@modelcontextprotocol/server-postgres",
           "postgresql://username:password@localhost:5432/freight_dev"
         ]
       }
     }
   }
   ```

4. **Environment Variables**
   Set up environment variables for secure database access:
   ```bash
   export DATABASE_URL="postgresql://username:password@localhost:5432/freight_dev"
   export POSTGRES_READ_ONLY=true
   ```

## Usage Examples

Once configured, you can use natural language queries like:

- "Show me the schema for the MigrationJob table"
- "List all failed migration jobs from the last 24 hours"  
- "Count the number of migration logs by status for tenant X"
- "Show me the top 5 tenants by migration job volume"
- "Find all jobs that have retry counts greater than 3"

## Security Considerations

- The server is configured for read-only access by default
- Tenant isolation is enforced at the application level
- Sensitive data should be masked in development environments
- Use connection pooling for production deployments

## Database Schema Reference

### Tables
- **tenants**: Tenant management and API keys
- **migration_jobs**: Job tracking and status
- **migration_logs**: Detailed record-level logging
- **retry_policies**: Configurable retry strategies

### Key Relationships
- Tenant → MigrationJobs (1:many)
- MigrationJob → MigrationLogs (1:many)
- MigrationJob → RetryPolicy (many:1)