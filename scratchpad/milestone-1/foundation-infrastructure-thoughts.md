# Milestone 1: Foundation & Infrastructure Thoughts

## Overview
Planning and decision notes for establishing core infrastructure with multi-tenant support.

## Multi-Tenant Architecture Decisions

### Database Strategy: Shared Database with Row-Level Security
**Decision**: Use shared tables with tenant_id column
**Rationale**:
- Simpler to manage than database-per-tenant
- Easier scaling and maintenance
- Cost-effective for SaaS model
- Can migrate to separate databases later if needed

**Implementation**:
```python
# Base model for all tenant-aware models
class TenantAwareModel(Base):
    __abstract__ = True
    tenant_id = Column(UUID, ForeignKey("tenants.id"), nullable=False, index=True)
```

### Tenant Isolation Patterns

1. **Database Level**:
   - Add tenant_id to all business tables
   - Create composite indexes: (tenant_id, other_columns)
   - Use PostgreSQL RLS as additional security layer

2. **Application Level**:
   - Middleware to inject tenant context
   - Query filters automatically applied
   - Prevent cross-tenant data access

3. **API Level**:
   - Require tenant identification in all requests
   - Validate tenant access rights
   - Rate limiting per tenant

## Authentication Strategy

### API Key Design
```
Structure: frt_live_<random_32_chars>
Example: frt_live_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

Prefixes:
- frt_live_: Production keys
- frt_test_: Test environment keys
- frt_dev_: Development keys
```

### Key Storage
- Hash keys using bcrypt before storage
- Store key prefix for quick lookups
- Log key usage for audit trail

## Database Schema Design

### Core Tables

```sql
-- Tenants table
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    api_key_hash VARCHAR(255) NOT NULL,
    api_key_prefix VARCHAR(20) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Migration jobs table
CREATE TABLE migration_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    source_system VARCHAR(50) NOT NULL, -- 'affinity'
    target_system VARCHAR(50) NOT NULL, -- 'attio'
    status VARCHAR(50) NOT NULL,
    config JSONB NOT NULL,
    total_records INTEGER DEFAULT 0,
    processed_records INTEGER DEFAULT 0,
    failed_records INTEGER DEFAULT 0,
    started_by VARCHAR(255) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete
    CONSTRAINT fk_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Create index for tenant isolation
CREATE INDEX idx_migration_jobs_tenant_id ON migration_jobs(tenant_id) WHERE deleted_at IS NULL;
```

## Redis Configuration

### Key Naming Convention
```
Pattern: freight:{tenant_id}:{resource}:{identifier}
Examples:
- freight:uuid:jobs:active - Active jobs for tenant
- freight:uuid:queue:high - High priority queue
- freight:uuid:locks:job_id - Distributed locks
```

### Connection Pooling
- Use redis-py with connection pooling
- Pool size: 50 connections (adjustable)
- Max connections per tenant: 10
- Connection timeout: 5 seconds

## Celery Architecture

### Queue Strategy
```
Queues:
- default: General tasks
- high_priority: Urgent retries, small batches
- low_priority: Large batch processing
- tenant_{id}: Optional per-tenant queues for isolation
```

### Worker Configuration
```python
# Celery configuration
CELERY_CONFIG = {
    'broker_url': 'redis://localhost:6379/0',
    'result_backend': 'redis://localhost:6379/1',
    'task_serializer': 'json',
    'accept_content': ['json'],
    'result_serializer': 'json',
    'timezone': 'UTC',
    'enable_utc': True,
    'worker_prefetch_multiplier': 4,
    'worker_max_tasks_per_child': 1000,
    'task_acks_late': True,
    'task_reject_on_worker_lost': True,
}
```

## Performance Considerations

### Database Optimizations
1. **Indexing Strategy**:
   - Primary: (tenant_id, status) for job queries
   - Secondary: (tenant_id, created_at) for time-based queries
   - Partial indexes for active records only

2. **Connection Pooling**:
   - SQLAlchemy pool size: 20
   - Max overflow: 40
   - Pool timeout: 30 seconds

3. **Query Optimization**:
   - Always filter by tenant_id first
   - Use EXPLAIN ANALYZE in development
   - Monitor slow query log

### Monitoring Strategy
- Application metrics: Response time, error rate
- Database metrics: Connection count, query time
- Queue metrics: Queue depth, processing time
- Worker metrics: Task completion rate, failures

## Security Checklist

- [ ] API keys are properly hashed
- [ ] Tenant isolation is enforced at all layers
- [ ] SQL injection prevention (parameterized queries)
- [ ] Rate limiting implemented
- [ ] Audit logging for all operations
- [ ] Encryption at rest configured
- [ ] TLS for all connections

## Testing Strategy

### Unit Tests
- Mock tenant context
- Test isolation logic
- Verify query filtering

### Integration Tests  
- Multi-tenant scenarios
- Cross-tenant access attempts
- Concurrent job processing

## Rollout Plan

1. Deploy schema migrations
2. Create test tenant
3. Verify isolation with test data
4. Load test with multiple tenants
5. Enable monitoring
6. Document operational procedures

## Open Issues

1. Should we implement tenant-specific rate limits from day one?
2. Do we need separate Redis databases per tenant?
3. How to handle tenant data export/deletion (GDPR)?
4. Backup strategy for multi-tenant data?

## Next Steps

1. Implement base models with tenant awareness
2. Create tenant middleware for FastAPI
3. Set up Alembic migrations
4. Write tenant isolation tests
5. Document API authentication