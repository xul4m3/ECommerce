# End-to-End Acceptance Test Scenarios

This directory contains comprehensive Gherkin scenarios for end-to-end testing of the multi-tenant e-commerce system. These scenarios cover all critical system behaviors and integration points.

## Test Coverage

### 1. Tenant Resolution (`tenant-resolution.feature`)
- Finbuckle.MultiTenant integration
- Resolution from X-Tenant-ID headers, JWT claims, and hostnames
- Priority order and validation
- Concurrent request isolation

### 2. PostgreSQL Tenant Isolation (`postgres-tenant-isolation.feature`)
- Single database with tenant_id column strategy
- Automatic tenant filtering in queries
- Cross-tenant data protection
- Same SKU across different tenants

### 3. Redis Cache Behavior (`redis-cache-behavior.feature`)
- Tenant-specific caching
- Cache invalidation strategies
- Distributed locking for stock management
- Session storage and TTL management
- Fallback behavior when Redis is unavailable

### 4. Transactional Outbox to Kafka (`transactional-outbox-kafka.feature`)
- Outbox pattern implementation
- Database transaction consistency
- Event ordering and tenant isolation
- Retry mechanisms and failure handling
- Idempotent event processing

### 5. Webhook Delivery with HMAC (`webhook-delivery-hmac.feature`)
- HMAC-SHA256 signature generation and verification
- Event filtering by subscription
- Delivery retry with exponential backoff
- Timeout and error handling
- Secret rotation support

### 6. Role-Based Access Control (`rbac-authorization.feature`)
- Multi-role hierarchy (Admin, TenantAdmin, Merchant, Customer)
- JWT token validation and role verification
- Cross-tenant access prevention
- Resource-level authorization
- API endpoint protection

### 7. Retry and Backoff Mechanisms (`retry-backoff-mechanisms.feature`)
- Exponential backoff with jitter
- Circuit breaker patterns
- Service-specific retry strategies
- Graceful degradation
- Environment-specific configuration

### 8. Dead Letter Handling (`dead-letter-handling.feature`)
- Failed operation tracking
- Manual and bulk reprocessing
- Alerting and monitoring integration
- Retention and archival policies
- Audit trails and recovery strategies

## Running the Tests

These Gherkin scenarios are designed to be used with:
- **SpecFlow** (.NET BDD framework)
- **Testcontainers** (for PostgreSQL, Redis, Kafka integration)
- **xUnit** or **NUnit** (test runners)

## Test Environment Requirements

- PostgreSQL (≥15) with test database
- Redis for caching and distributed locks
- Apache Kafka for event streaming
- .NET 8 runtime
- Docker (for Testcontainers)

## Scenario Structure

Each scenario follows the standard Given-When-Then format:
- **Given**: Test setup and preconditions
- **When**: Action or trigger
- **Then**: Expected outcomes and assertions

## Integration Points Tested

1. **Multi-tenant Context Resolution**: Finbuckle middleware integration
2. **Data Isolation**: PostgreSQL tenant filtering
3. **Caching Layer**: Redis integration and invalidation
4. **Event Streaming**: Kafka publishing with outbox pattern
5. **External Integration**: Webhook delivery with security
6. **Authorization**: JWT-based RBAC enforcement
7. **Resilience**: Retry, backoff, and failure handling
8. **Monitoring**: Dead letter queues and alerting

## Test Data Management

Each scenario includes:
- Background setup with test data
- Tenant-specific test contexts
- Realistic business scenarios
- Error condition testing
- Performance and concurrency validation

These scenarios ensure comprehensive coverage of the multi-tenant e-commerce system's critical functionality and integration points.