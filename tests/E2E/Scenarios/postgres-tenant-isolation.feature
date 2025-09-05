Feature: PostgreSQL Tenant Isolation
  As a system
  I want to ensure tenant data isolation in a single PostgreSQL database
  So that tenants cannot access each other's data

  Background:
    Given the PostgreSQL database is configured with tenant isolation
    And the following tenants exist:
      | tenant_id | name      |
      | tenant-a  | Company A |
      | tenant-b  | Company B |
    And the following products exist:
      | id | tenant_id | sku      | name         | price_cents |
      | 1  | tenant-a  | PROD-001 | Widget A     | 1000        |
      | 2  | tenant-a  | PROD-002 | Gadget A     | 2000        |
      | 3  | tenant-b  | PROD-001 | Widget B     | 1500        |
      | 4  | tenant-b  | PROD-003 | Tool B       | 3000        |

  Scenario: Query products with tenant isolation
    Given I am authenticated as tenant "tenant-a"
    When I request all products
    Then I should only see products for "tenant-a":
      | sku      | name     | price_cents |
      | PROD-001 | Widget A | 1000        |
      | PROD-002 | Gadget A | 2000        |
    And I should not see any products from "tenant-b"

  Scenario: Create product with automatic tenant_id injection
    Given I am authenticated as tenant "tenant-a"
    When I create a product with:
      | sku      | name      | price_cents |
      | PROD-004 | NewItem A | 2500        |
    Then the product should be created with tenant_id "tenant-a"
    And querying products for "tenant-a" should include the new product
    And querying products for "tenant-b" should not include the new product

  Scenario: Attempt to access other tenant's data via direct ID
    Given I am authenticated as tenant "tenant-a"
    When I try to access product with id "3" (which belongs to tenant-b)
    Then the request should return 404 Not Found
    And no data should be returned

  Scenario: Update operation respects tenant isolation
    Given I am authenticated as tenant "tenant-a"
    When I update product "1" with name "Updated Widget A"
    Then the product should be updated successfully
    And only the product in "tenant-a" should be affected
    And products in "tenant-b" should remain unchanged

  Scenario: Cross-tenant data visibility in admin operations
    Given I am authenticated as a platform admin
    When I request products across all tenants
    Then I should see products from all tenants:
      | tenant_id | sku      | name     |
      | tenant-a  | PROD-001 | Widget A |
      | tenant-a  | PROD-002 | Gadget A |
      | tenant-b  | PROD-001 | Widget B |
      | tenant-b  | PROD-003 | Tool B   |

  Scenario: Database constraints prevent cross-tenant data corruption
    Given I have database access
    When I attempt to manually insert a product with missing tenant_id
    Then the database should reject the operation
    And a constraint violation error should be raised

  Scenario: Tenant filtering applied to all related entities
    Given I am authenticated as tenant "tenant-a"
    And there are orders linking to products
    When I query orders
    Then I should only see orders for "tenant-a"
    And all related order_items should only reference products from "tenant-a"
    And no cross-tenant data should be visible in joins

  Scenario: Same SKU across different tenants
    Given products with same SKU exist in different tenants
    When I am authenticated as tenant "tenant-a" and query for "PROD-001"
    Then I should only see the "PROD-001" product for "tenant-a"
    And the product details should be specific to "tenant-a"
    When I am authenticated as tenant "tenant-b" and query for "PROD-001"
    Then I should only see the "PROD-001" product for "tenant-b"
    And the product details should be specific to "tenant-b"