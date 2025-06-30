# Milestone 2: Core Processing Engine Thoughts

## Overview
Design decisions and implementation notes for the job processing engine with retry capabilities.

## Batch Processing Architecture

### Batch Size Strategy
```python
DEFAULT_BATCH_SIZE = 1000
MIN_BATCH_SIZE = 100
MAX_BATCH_SIZE = 10000

# Dynamic batch sizing based on record type
BATCH_SIZE_BY_TYPE = {
    "contacts": 1000,
    "companies": 500,
    "notes": 2000,
    "activities": 1500,
    "files": 100,  # Smaller batches for file transfers
}
```

### Batch State Machine
```
States:
PENDING -> PROCESSING -> COMPLETED
                     -> FAILED -> RETRYING -> COMPLETED
                                           -> FAILED_FINAL
```

## Retry Mechanism Design

### Exponential Backoff Algorithm
```python
def calculate_retry_delay(retry_count: int) -> int:
    """Calculate delay in seconds using exponential backoff with jitter."""
    base_delay = 2  # seconds
    max_delay = 3600  # 1 hour
    
    # Exponential backoff: 2^retry_count
    delay = min(base_delay ** retry_count, max_delay)
    
    # Add jitter to prevent thundering herd
    jitter = random.uniform(0, delay * 0.1)
    
    return int(delay + jitter)

# Retry sequence: 2s, 4s, 8s, 16s, 32s, 64s, 128s, 256s, 512s, 1024s, 3600s...
```

### Retry Configuration Schema
```python
class RetryPolicy(BaseModel):
    max_attempts: int = 5
    backoff_type: str = "exponential"  # or "linear", "fixed"
    initial_delay: int = 2  # seconds
    max_delay: int = 3600  # seconds
    retry_on_errors: List[str] = ["timeout", "rate_limit", "temporary_failure"]
    fatal_errors: List[str] = ["invalid_credentials", "not_found", "permission_denied"]
```

### Smart Retry Logic
1. **Error Classification**:
   - Transient: Network timeouts, rate limits, 503 errors
   - Permanent: 404, 401, validation errors
   - Unknown: Treat as transient with limited retries

2. **Retry Strategies by Error Type**:
   ```python
   RETRY_STRATEGIES = {
       "rate_limit": {
           "max_attempts": 10,
           "backoff_type": "exponential",
           "respect_retry_after": True
       },
       "timeout": {
           "max_attempts": 3,
           "backoff_type": "linear",
           "initial_delay": 5
       },
       "api_error_5xx": {
           "max_attempts": 5,
           "backoff_type": "exponential",
           "alert_after_attempts": 3
       }
   }
   ```

## Worker Task Structure

### Base Task Class
```python
class BaseMigrationTask(celery.Task):
    autoretry_for = (TemporaryFailure, RateLimitError)
    retry_kwargs = {'max_retries': 5}
    retry_backoff = True
    retry_backoff_max = 3600
    retry_jitter = True
    
    def before_start(self, task_id, args, kwargs):
        """Initialize task context and logging."""
        self.tenant_id = kwargs.get('tenant_id')
        self.job_id = kwargs.get('job_id')
        self.batch_id = kwargs.get('batch_id')
        self.start_time = time.time()
        
    def on_failure(self, exc, task_id, args, kwargs, einfo):
        """Handle task failure and logging."""
        log_task_failure(
            tenant_id=self.tenant_id,
            job_id=self.job_id,
            batch_id=self.batch_id,
            error=str(exc),
            traceback=str(einfo)
        )
        
    def on_success(self, retval, task_id, args, kwargs):
        """Update job progress and metrics."""
        update_job_progress(
            job_id=self.job_id,
            processed_records=retval['processed'],
            failed_records=retval['failed']
        )
```

### Main Processing Task
```python
@celery_app.task(bind=True, base=BaseMigrationTask)
def process_migration_batch(self, tenant_id: str, job_id: str, batch_id: str, 
                          records: List[dict], config: dict):
    """Process a batch of records for migration."""
    
    results = {
        'processed': 0,
        'failed': 0,
        'errors': []
    }
    
    # Initialize API clients with tenant credentials
    source_client = AffinityClient(config['source_credentials'])
    target_client = AttioClient(config['target_credentials'])
    
    for record in records:
        try:
            # Transform record
            transformed = transform_record(record, config['mapping'])
            
            # Migrate to target system
            target_client.create_record(transformed)
            
            # Log success
            log_record_success(tenant_id, job_id, record['id'])
            results['processed'] += 1
            
        except RateLimitError as e:
            # Re-raise for Celery retry
            self.retry(exc=e, countdown=e.retry_after)
            
        except TemporaryFailure as e:
            # Re-raise for automatic retry
            raise
            
        except Exception as e:
            # Log failure and continue
            log_record_failure(tenant_id, job_id, record['id'], str(e))
            results['failed'] += 1
            results['errors'].append({
                'record_id': record['id'],
                'error': str(e)
            })
    
    return results
```

## Error Handling Patterns

### Custom Exception Hierarchy
```python
class MigrationError(Exception):
    """Base exception for migration errors."""
    pass

class TemporaryFailure(MigrationError):
    """Errors that should trigger retry."""
    pass

class PermanentFailure(MigrationError):
    """Errors that should not be retried."""
    pass

class RateLimitError(TemporaryFailure):
    """Rate limit exceeded, includes retry_after."""
    def __init__(self, message: str, retry_after: int = 60):
        super().__init__(message)
        self.retry_after = retry_after

class DataValidationError(PermanentFailure):
    """Data doesn't meet target system requirements."""
    pass

class AuthenticationError(PermanentFailure):
    """Invalid credentials or permissions."""
    pass
```

### Circuit Breaker Pattern
```python
class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
        
    def call(self, func, *args, **kwargs):
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = "HALF_OPEN"
            else:
                raise CircuitOpenError("Circuit breaker is OPEN")
        
        try:
            result = func(*args, **kwargs)
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self.failure_count = 0
            return result
            
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"
                
            raise
```

## Logging Architecture

### Structured Logging Format
```python
import structlog

logger = structlog.get_logger()

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

# Usage example
logger.info("batch_processing_started",
    tenant_id=tenant_id,
    job_id=job_id,
    batch_id=batch_id,
    record_count=len(records),
    batch_size=config['batch_size']
)
```

### Log Aggregation Strategy
1. **Application Logs**: JSON format to stdout
2. **Task Logs**: Stored in PostgreSQL with record-level detail
3. **Metrics**: StatsD format for monitoring
4. **Audit Trail**: Separate table for compliance

## Performance Optimization

### Batch Processing Optimizations
1. **Bulk Operations**: Use bulk APIs where available
2. **Connection Pooling**: Reuse API clients across tasks
3. **Parallel Processing**: Process independent records concurrently
4. **Memory Management**: Stream large datasets instead of loading

### Celery Optimizations
```python
# Worker configuration for optimal performance
CELERY_WORKER_CONFIG = {
    'worker_prefetch_multiplier': 1,  # Prevent task hoarding
    'task_acks_late': True,  # Acknowledge after completion
    'worker_max_tasks_per_child': 1000,  # Prevent memory leaks
    'worker_disable_rate_limits': False,  # Respect rate limits
    'task_time_limit': 3600,  # 1 hour hard limit
    'task_soft_time_limit': 3000,  # 50 min soft limit
}
```

## Monitoring and Alerting

### Key Metrics to Track
1. **Task Metrics**:
   - Tasks per second
   - Task duration (p50, p95, p99)
   - Task failure rate
   - Retry rate by error type

2. **Job Metrics**:
   - Records processed per minute
   - Job completion time
   - Error rate by tenant
   - Queue depth

3. **System Metrics**:
   - Worker CPU/memory usage
   - Redis memory usage
   - Database connections
   - API rate limit usage

### Alert Conditions
```yaml
alerts:
  - name: high_failure_rate
    condition: failure_rate > 0.1  # 10%
    duration: 5m
    severity: warning
    
  - name: stuck_jobs
    condition: job_no_progress > 30m
    severity: critical
    
  - name: queue_backup
    condition: queue_depth > 10000
    severity: warning
    
  - name: worker_memory_high
    condition: worker_memory_percent > 80
    severity: warning
```

## Testing Strategies

### Unit Tests
```python
def test_exponential_backoff():
    """Test retry delay calculation."""
    assert calculate_retry_delay(0) >= 2
    assert calculate_retry_delay(1) >= 4
    assert calculate_retry_delay(10) == 3600  # Max delay

def test_batch_processing_with_failures():
    """Test batch processing with mixed success/failure."""
    records = [{"id": i} for i in range(100)]
    # Mock 10% failure rate
    with patch('target_client.create_record') as mock_create:
        mock_create.side_effect = [None] * 90 + [Exception("API Error")] * 10
        
        result = process_migration_batch.apply(args=[...])
        assert result['processed'] == 90
        assert result['failed'] == 10
```

### Integration Tests
- Test with real Redis/PostgreSQL using testcontainers
- Simulate API rate limits and errors
- Test retry mechanisms end-to-end
- Verify data consistency after retries

## Deployment Considerations

### Worker Deployment
```yaml
# docker-compose.yml for workers
services:
  worker-default:
    image: freight/worker:latest
    command: celery -A freight.worker worker -Q default -n worker-default@%h
    deploy:
      replicas: 4
    environment:
      - CELERY_WORKER_CONCURRENCY=4
      
  worker-high-priority:
    image: freight/worker:latest  
    command: celery -A freight.worker worker -Q high_priority -n worker-high@%h
    deploy:
      replicas: 2
    environment:
      - CELERY_WORKER_CONCURRENCY=2
```

### Scaling Strategy
1. **Horizontal Scaling**: Add more workers for higher throughput
2. **Vertical Scaling**: Increase worker concurrency for I/O bound tasks
3. **Queue Sharding**: Separate queues by tenant or priority
4. **Auto-scaling**: Based on queue depth and processing time

## Next Steps

1. Implement base task class with retry logic
2. Create error classification system
3. Build circuit breaker for external APIs
4. Set up structured logging
5. Write comprehensive test suite