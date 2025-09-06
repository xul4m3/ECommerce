Feature: Tenant Resolution via Finbuckle
  As a system
  I want to resolve tenant context from various sources
  So that multi-tenant operations are properly isolated

  Background:
    Given the system is configured with Finbuckle.MultiTenant
    And the following tenants exist:
      | tenant_id | name          | status |
      | tenant-a  | Company A     | active |
      | tenant-b  | Company B     | active |
      | tenant-c  | Company C     | inactive |

  Scenario: Resolve tenant from X-Tenant-ID header
    Given I have a valid API request
    When I send a request with header "X-Tenant-ID: tenant-a"
    Then the tenant context should be resolved to "tenant-a"
    And all database queries should include tenant filter for "tenant-a"

  Scenario: Resolve tenant from JWT claim
    Given I have a valid JWT token with claim "tenant_id: tenant-b"
    When I send an authenticated request with the JWT token
    Then the tenant context should be resolved to "tenant-b"
    And all database queries should include tenant filter for "tenant-b"

  Scenario: Resolve tenant from hostname
    Given the hostname resolution is configured
    And hostname "companya.ecommerce.com" maps to "tenant-a"
    When I send a request to "companya.ecommerce.com"
    Then the tenant context should be resolved to "tenant-a"
    And all database queries should include tenant filter for "tenant-a"

  Scenario: Priority order - JWT overrides header
    Given I have a valid JWT token with claim "tenant_id: tenant-b"
    When I send a request with header "X-Tenant-ID: tenant-a" and the JWT token
    Then the tenant context should be resolved to "tenant-b"
    And the header value should be ignored

  Scenario: Reject request for inactive tenant
    Given I have a valid API request
    When I send a request with header "X-Tenant-ID: tenant-c"
    Then the request should be rejected with status 403
    And the error message should indicate "Tenant inactive"

  Scenario: Reject request without tenant context
    Given I have a valid API request
    When I send a request without any tenant identification
    Then the request should be rejected with status 400
    And the error message should indicate "Tenant context required"

  Scenario: Tenant isolation in concurrent requests
    Given I have multiple concurrent requests
    When I send request 1 with "X-Tenant-ID: tenant-a"
    And I send request 2 with "X-Tenant-ID: tenant-b" simultaneously
    Then request 1 should have tenant context "tenant-a"
    And request 2 should have tenant context "tenant-b"
    And the tenant contexts should not interfere with each other