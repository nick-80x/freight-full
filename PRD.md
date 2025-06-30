# 🧾 Product Requirements Document (PRD)

## 📌 Product Overview

**Name:** Freight
**Type:** SaaS – Data Migration Tool (Affinity → Attio)
**Users:** Migration engineers, SaaS onboarding teams, system admins

---

## 🎯 Goals

* Accurately migrate large volumes of data from Affinity to Attio
* Support multiple concurrent migrations (multi-tenant)
* Enable detailed retry mechanisms
* Provide audit logs and job reports
* Ensure end-to-end security and data isolation per tenant

---

## 👥 Personas

### Migration Engineer

* Creates jobs
* Monitors progress
* Triggers retries

### Account Manager

* Reviews status for a specific tenant
* Downloads reports

### System Admin

* Monitors platform usage
* Audits tenant activity
* Ensures tenant isolation and data security

---

## 🔑 Features

### 1. Migration Job Management

* Create jobs (Affinity → Attio)
* Configure batch size, retries
* Track metadata & timestamps

### 2. Retry System

* Auto-retry failed batches
* Manual retry (per batch/job)
* Retry policies: max attempts, exponential backoff

### 3. Concurrency & Batching

* Jobs split into batches
* Parallel processing with Celery
* Configurable thread pool size

### 4. Multi-Tenancy

* Tenant ID required in all requests
* Isolation enforced in API and DB
* Per-tenant access keys or scoped tokens
* Secure tenant data isolation: no data overlap between tenants

### 5. Logging & Audit Trail

* Log status per record (success, fail, retry)
* Timestamps, error details, retry count
* Logs accessible via API & downloadable

### 6. Reporting

* Job summaries
* Failure breakdown
* CSV export

### 7. Authentication & Roles

* JWT or API keys
* Tenant vs. Admin roles
* Role-based access control (RBAC)

### 8. Web Interface (Next.js UI)

* Dashboard for migration jobs
* Progress indicators
* Retry controls
* Log/report downloads

### 9. File & Backup Storage

* Use **Amazon S3** to store:

  * Migrated file data
  * Large temporary datasets
  * Full backups of job runs for recovery/auditing

### 10. Security & Encryption

* **Encryption in transit** using HTTPS for all APIs and S3 operations
* **Encryption at rest** enabled for:

  * Amazon S3 (SSE-S3 or SSE-KMS)
  * PostgreSQL storage layer
  * Redis connections with TLS
* Environment variables and secrets stored securely (Railway, GitHub Actions)

---

## 🧪 Test Plan Summary

* **Unit tests:** API endpoints, data transformers, Celery task logic
* **Integration tests:** Simulate Affinity to Attio migrations, including failure cases
* **Load testing:** Batch processing of 100K+ records
* **Security testing:** Tenant isolation, token auth, rate limits
* **Monitoring coverage:** Sentry tracking for errors, Grafana alerts for queue delays

---

## 🔗 Integration Touchpoints

* **Affinity API:** Data source
* **Attio API:** Target platform for migration
* **S3:** Storage for temporary/backup data
* **Redis:** Broker for Celery task queue
* **PostgreSQL:** Internal job state and logging DB
* **Auth0 (optional):** Multi-tenant auth handling

---

## 📈 Metrics & Monitoring Plan

* **System metrics:** CPU/memory, DB connection count, Redis queue length
* **Application metrics:**

  * Records processed per minute
  * Job failure rate per tenant
  * Average retry count per job
  * API error rate (HTTP 5xx)
* **Tools:** Grafana dashboards, Prometheus exporters, Sentry alerts
* **Alerting thresholds:**

  * Redis latency > 100ms
  * Job retry rate > 5%
  * Worker crash or timeout events

---

## 🚦 Service Status & Health Checks

* **/ping or /health route:** FastAPI health check for liveness probe
* **Celery worker heartbeat:** Monitored by Flower and/or Prometheus
* **Database availability checks:** Periodic connection test
* **Redis status probe:** Liveness & readiness via queue pings

---

## 📚 Glossary & Terminology

* **Tenant:** A company or account using the Freight platform
* **Migration Job:** A full end-to-end data migration run from Affinity to Attio
* **Batch:** A chunk of records processed within a migration job
* **Retry:** Re-attempting failed batches or records
* **Record:** An individual item (e.g. contact, company, note) being migrated
* **Log:** The outcome and metadata for a single record or batch (status, timestamp)

---

## 🏗️ Tech Stack

| Layer      | Technology        |
| ---------- | ----------------- |
| Frontend   | Next.js (Vercel)  |
| API        | FastAPI (Python)  |
| Job Queue  | Celery + Redis    |
| Database   | PostgreSQL        |
| Storage    | **Amazon S3**     |
| Logging    | DB logs + Sentry  |
| Monitoring | Flower + Grafana  |
| Auth       | API keys or Auth0 |

---

## 📊 Data Models (Simplified)

### Tenant

* `id` (UUID)
* `name` (text)
* `api_key` (text)

### MigrationJob

* `id` (UUID)
* `tenant_id` (FK)
* `status` (enum: pending, running, completed, failed)
* `record_count` (int)
* `failed_batches` (int)
* `started_by` (string)
* `created_at`, `updated_at` (timestamp)

### MigrationLog

* `id` (UUID)
* `job_id` (FK)
* `tenant_id` (FK)
* `record_id` (string)
* `status` (enum: success, failed, retrying)
* `error_message` (text)
* `retry_count` (int)
* `timestamp` (timestamp)

---

## 📈 Performance Targets

| Metric          | Target                     |
| --------------- | -------------------------- |
| Concurrent jobs | 50+ at once                |
| Throughput      | 10K records/min per worker |
| Retry latency   | Batches < 1s if possible   |
| API uptime      | 99.9%                      |

---

## 🧱 Milestones

### Milestone 1: Core Infra + Multi-tenancy

* FastAPI project setup
* Tenant-aware models and middleware
* PostgreSQL + Redis + Celery setup
* Auth with API key headers

### Milestone 2: Retry-Enabled Worker System

* Celery worker with retry logic
* Logging per record with retry count
* Flower for monitoring

### Milestone 3: API + Admin Dashboard

* Create/view jobs by tenant
* Expose retry endpoints
* Job detail view via API

### Milestone 4: Reporting & Audit Logs

* CSV export of logs
* Job summaries with stats
* Web dashboard integration

### Milestone 5: Deployment & Scaling

* Dockerize backend and workers
* CI/CD pipeline
* Deploy to Render, ECS, or Railway
* Load testing

---

## 📦 Optional Enhancements

* WebSocket support for live job updates
* Notification system (email/Slack)
* API rate limiting and tenant quotas
* Dead-letter queue for failed batches
