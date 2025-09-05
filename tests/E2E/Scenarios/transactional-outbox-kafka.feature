Feature: Transactional Outbox to Kafka
  As a system
  I want to ensure reliable event publishing using the transactional outbox pattern
  So that domain events are never lost and exactly-once delivery is guaranteed

  Background:
    Given the system is configured with transactional outbox pattern
    And Kafka is available and configured
    And the following tenants exist:
      | tenant_id | name      |
      | tenant-a  | Company A |
      | tenant-b  | Company B |

  Scenario: Order creation triggers outbox event
    Given I am authenticated as tenant "tenant-a"
    When I create an order with the following details:
      | customer_id | total_cents | currency |
      | CUST-001    | 2500        | USD      |
    Then the order should be saved in the orders table
    And an outbox event should be created in the same database transaction:
      | aggregate_type | aggregate_id | event_type    | tenant_id |
      | Order          | [order-id]   | OrderCreated  | tenant-a  |
    And the outbox event status should be "pending"
    And both operations should succeed or fail together

  Scenario: Background worker processes outbox events
    Given there are pending outbox events:
      | id | aggregate_type | event_type   | tenant_id | status  |
      | 1  | Order          | OrderCreated | tenant-a  | pending |
      | 2  | Product        | ProductAdded | tenant-b  | pending |
    When the outbox background worker runs
    Then events should be published to Kafka topics:
      | topic              | partition_key | tenant_id |
      | order-events       | tenant-a      | tenant-a  |
      | product-events     | tenant-b      | tenant-b  |
    And outbox event statuses should be updated to "published"
    And published_at timestamp should be set

  Scenario: Kafka unavailable during outbox processing
    Given there are pending outbox events
    And Kafka is temporarily unavailable
    When the outbox background worker runs
    Then events should remain in "pending" status
    And attempt count should be incremented
    And last_attempt_at timestamp should be updated
    And events should be retried on next worker execution

  Scenario: Outbox event retry with exponential backoff
    Given an outbox event has failed 3 times
    When the background worker processes the event again
    Then the retry delay should follow exponential backoff (1s, 2s, 4s, 8s)
    And the event should not be processed until the delay has elapsed
    And the attempt count should be incremented to 4

  Scenario: Maximum retry attempts reached
    Given an outbox event has failed 5 times (maximum attempts)
    When the background worker processes the event
    Then the event status should be changed to "failed"
    And the event should not be retried further
    And an alert should be generated for manual intervention
    And the event should be logged for dead letter handling

  Scenario: Idempotent event processing
    Given an outbox event is published to Kafka
    And the same event is processed again due to worker restart
    When the Kafka consumer receives the duplicate event
    Then the consumer should detect the duplicate using event ID
    And the duplicate event should be ignored
    And no side effects should occur

  Scenario: Event ordering within tenant
    Given multiple events exist for tenant "tenant-a":
      | id | event_type    | created_at                |
      | 1  | OrderCreated  | 2024-01-01T10:00:00Z     |
      | 2  | OrderUpdated  | 2024-01-01T10:01:00Z     |
      | 3  | OrderPaid     | 2024-01-01T10:02:00Z     |
    When the outbox worker processes these events
    Then events should be published to Kafka in order of creation
    And all events should use the same partition key (tenant_id)
    And event ordering should be preserved within the tenant partition

  Scenario: Cross-tenant event isolation
    Given there are outbox events for multiple tenants:
      | tenant_id | event_type   |
      | tenant-a  | OrderCreated |
      | tenant-b  | OrderCreated |
    When events are published to Kafka
    Then events should be routed to different partitions based on tenant_id
    And tenant "tenant-a" events should not affect tenant "tenant-b" processing
    And each tenant should maintain independent event ordering

  Scenario: Outbox table cleanup
    Given outbox events that are older than 30 days and published
    When the cleanup process runs
    Then old published events should be archived or deleted
    And pending or failed events should be retained regardless of age
    And system performance should not be affected by table size

  Scenario: Database transaction rollback
    Given I am creating an order that will cause a business rule violation
    When the order creation fails after outbox event is written
    Then the entire transaction should be rolled back
    And no order should exist in the orders table
    And no outbox event should exist in the outbox_events table
    And data consistency should be maintained