Feature: Role-Based Access Control (RBAC)
  As a system
  I want to enforce role-based access control
  So that users can only access resources and perform actions appropriate to their roles

  Background:
    Given the system is configured with RBAC
    And the following roles exist:
      | role_name     | description                          |
      | Admin         | Platform administrator               |
      | TenantAdmin   | Tenant administrator                 |
      | Merchant      | Tenant merchant/seller              |
      | Customer      | Tenant customer/buyer               |
    And the following tenants exist:
      | tenant_id | name      |
      | tenant-a  | Company A |
      | tenant-b  | Company B |
    And the following users exist:
      | user_id | tenant_id | email                | roles       |
      | user-1  | platform  | admin@platform.com   | Admin       |
      | user-2  | tenant-a  | admin@companya.com   | TenantAdmin |
      | user-3  | tenant-a  | merchant@companya.com| Merchant    |
      | user-4  | tenant-a  | customer@companya.com| Customer    |
      | user-5  | tenant-b  | merchant@companyb.com| Merchant    |

  Scenario: Platform Admin can access all tenants
    Given I am authenticated as user "user-1" with role "Admin"
    When I request to view all tenants
    Then I should see all tenants:
      | tenant_id | name      |
      | tenant-a  | Company A |
      | tenant-b  | Company B |
    And I should be able to manage platform-wide settings

  Scenario: Platform Admin can manage any tenant's data
    Given I am authenticated as user "user-1" with role "Admin"
    When I request to view products for tenant "tenant-a"
    Then I should see all products for "tenant-a"
    When I request to view products for tenant "tenant-b"
    Then I should see all products for "tenant-b"

  Scenario: Tenant Admin can only access their own tenant
    Given I am authenticated as user "user-2" with role "TenantAdmin" for "tenant-a"
    When I request to view products for tenant "tenant-a"
    Then I should see all products for "tenant-a"
    When I request to view products for tenant "tenant-b"
    Then I should receive a 403 Forbidden error
    And the error should indicate insufficient permissions

  Scenario: Tenant Admin can manage users within their tenant
    Given I am authenticated as user "user-2" with role "TenantAdmin" for "tenant-a"
    When I create a new user for tenant "tenant-a"
    Then the user should be created successfully
    When I try to create a user for tenant "tenant-b"
    Then I should receive a 403 Forbidden error

  Scenario: Merchant can manage products but not users
    Given I am authenticated as user "user-3" with role "Merchant" for "tenant-a"
    When I create a new product for tenant "tenant-a"
    Then the product should be created successfully
    When I try to create a new user for tenant "tenant-a"
    Then I should receive a 403 Forbidden error
    And the error should indicate insufficient role permissions

  Scenario: Customer can only view products and manage their own orders
    Given I am authenticated as user "user-4" with role "Customer" for "tenant-a"
    When I request to view products for tenant "tenant-a"
    Then I should see all available products for "tenant-a"
    When I create an order for myself
    Then the order should be created successfully
    When I try to view another customer's orders
    Then I should receive a 403 Forbidden error

  Scenario: Cross-tenant access is denied for non-admin users
    Given I am authenticated as user "user-3" with role "Merchant" for "tenant-a"
    When I try to access any resource for tenant "tenant-b"
    Then I should receive a 403 Forbidden error
    And the error should indicate cross-tenant access denied

  Scenario: JWT token validation includes role verification
    Given I have a JWT token with claims:
      | claim     | value     |
      | sub       | user-3    |
      | tenant_id | tenant-a  |
      | roles     | Merchant  |
    When I access an endpoint requiring "Merchant" role
    Then the request should be authorized
    When I access an endpoint requiring "TenantAdmin" role
    Then I should receive a 403 Forbidden error

  Scenario: Expired or invalid JWT tokens are rejected
    Given I have an expired JWT token
    When I make any authenticated request
    Then I should receive a 401 Unauthorized error
    Given I have a JWT token with invalid signature
    When I make any authenticated request
    Then I should receive a 401 Unauthorized error

  Scenario: Role hierarchy enforcement
    Given role hierarchy is: Admin > TenantAdmin > Merchant > Customer
    When a user with "TenantAdmin" role accesses an endpoint requiring "Merchant" role
    Then the request should be authorized (higher role includes lower privileges)
    When a user with "Customer" role accesses an endpoint requiring "Merchant" role
    Then I should receive a 403 Forbidden error

  Scenario: Tenant-specific role verification
    Given I am authenticated as user "user-5" with role "Merchant" for "tenant-b"
    When I verify my roles for tenant "tenant-b"
    Then I should have "Merchant" role for "tenant-b"
    When I verify my roles for tenant "tenant-a"
    Then I should have no roles for "tenant-a"
    And cross-tenant operations should be denied

  Scenario: Resource-level authorization
    Given I am authenticated as user "user-4" with role "Customer" for "tenant-a"
    And I have an order with id "order-123"
    When I try to access "order-123" (my own order)
    Then the request should be authorized
    When I try to access "order-456" (another customer's order)
    Then I should receive a 403 Forbidden error

  Scenario: Multiple roles per user
    Given user "user-2" has roles "TenantAdmin,Merchant" for "tenant-a"
    When I access an endpoint requiring "TenantAdmin" role
    Then the request should be authorized
    When I access an endpoint requiring "Merchant" role
    Then the request should be authorized
    When I access an endpoint requiring "Customer" role
    Then the request should be authorized (role hierarchy)

  Scenario: API endpoint protection
    Given the following API endpoints are protected:
      | endpoint                    | required_role |
      | GET /api/v1/platform/*      | Admin        |
      | POST /api/v1/tenants/*/users| TenantAdmin  |
      | POST /api/v1/products       | Merchant     |
      | GET /api/v1/products        | Customer     |
    When users access these endpoints with appropriate roles
    Then all requests should be authorized
    When users access these endpoints with insufficient roles
    Then all requests should be denied with 403 Forbidden