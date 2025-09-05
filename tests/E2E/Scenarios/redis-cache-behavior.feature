Feature: Redis Cache Behavior
  As a system
  I want to use Redis for caching and distributed locking
  So that performance is optimized and concurrency is managed

  Background:
    Given Redis is configured and available
    And the following tenants exist:
      | tenant_id | name      |
      | tenant-a  | Company A |
      | tenant-b  | Company B |

  Scenario: Cache product data per tenant
    Given I am authenticated as tenant "tenant-a"
    And product data exists in PostgreSQL for "tenant-a"
    When I request product listing for the first time
    Then the data should be fetched from PostgreSQL
    And the product listing should be cached in Redis with key "products:tenant-a"
    When I request the same product listing again
    Then the data should be served from Redis cache
    And PostgreSQL should not be queried

  Scenario: Cache invalidation on product update
    Given I am authenticated as tenant "tenant-a"
    And product listing is cached in Redis for "tenant-a"
    When I update a product in "tenant-a"
    Then the cache key "products:tenant-a" should be invalidated
    And the next product listing request should fetch fresh data from PostgreSQL
    And the cache should be repopulated with updated data

  Scenario: Tenant-specific cache isolation
    Given I am authenticated as tenant "tenant-a"
    And product listing is cached for "tenant-a"
    When I switch to tenant "tenant-b" context
    And request product listing
    Then the cache should not return data from "tenant-a"
    And fresh data should be fetched from PostgreSQL for "tenant-b"
    And separate cache key "products:tenant-b" should be created

  Scenario: Distributed locking for stock management
    Given product "PROD-001" has stock of 10 in tenant "tenant-a"
    When two concurrent orders attempt to reserve 8 units each
    Then a distributed lock should be acquired using Redis key "stock:tenant-a:PROD-001"
    And only the first order should succeed in reserving 8 units
    And the second order should wait for the lock and then get remaining 2 units
    And the final stock should be 0 without overselling

  Scenario: Session storage in Redis
    Given I have an authenticated user session for tenant "tenant-a"
    When I store session data in Redis
    Then the session should be keyed with "session:tenant-a:user-id"
    And session data should be retrievable across multiple requests
    And session should expire according to configured TTL

  Scenario: Cache TTL and expiration
    Given I cache product data with TTL of 300 seconds
    When 300 seconds pass
    Then the cache entry should be automatically expired
    And the next request should fetch fresh data from PostgreSQL
    And the cache should be repopulated

  Scenario: Redis connection failure fallback
    Given Redis is temporarily unavailable
    When I request product listing
    Then the system should fallback to PostgreSQL
    And the response should be returned successfully without caching
    And appropriate logging should indicate Redis unavailability
    When Redis becomes available again
    Then caching should resume normally

  Scenario: Cache warm-up on application start
    Given the application is starting up
    When the warm-up process begins
    Then frequently accessed data should be pre-loaded into Redis
    And cache hit rates should be improved for initial requests
    And warm-up should respect tenant boundaries

  Scenario: Memory management and cache eviction
    Given Redis is at memory capacity
    When new cache entries are added
    Then least recently used entries should be evicted according to LRU policy
    And cache operations should not fail due to memory constraints
    And application performance should remain stable