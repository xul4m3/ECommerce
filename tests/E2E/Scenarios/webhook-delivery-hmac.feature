Feature: Webhook Delivery with HMAC
  As a system
  I want to deliver webhooks securely with HMAC signatures
  So that webhook consumers can verify message authenticity and integrity

  Background:
    Given the webhook system is configured
    And the following tenants with webhook configurations exist:
      | tenant_id | webhook_url                      | secret         | events_subscribed    |
      | tenant-a  | https://api.companya.com/webhook | secret-a-123   | order.*,product.*   |
      | tenant-b  | https://api.companyb.com/webhook | secret-b-456   | order.created       |

  Scenario: Webhook delivery with HMAC-SHA256 signature
    Given an order is created for tenant "tenant-a"
    When the webhook delivery is triggered
    Then a POST request should be sent to "https://api.companya.com/webhook"
    And the request should include headers:
      | header_name   | header_value                                    |
      | Content-Type  | application/json                                |
      | X-Event-Type  | order.created                                   |
      | X-Tenant-ID   | tenant-a                                        |
      | X-Signature   | sha256=[computed-hmac-of-payload-with-secret-a] |
    And the payload should be valid JSON containing order details
    And the HMAC signature should be computed using secret "secret-a-123"

  Scenario: Webhook consumer verifies HMAC signature
    Given a webhook request is received with:
      | payload      | {"order_id": "12345", "status": "created"}           |
      | signature    | sha256=abc123def456                                  |
      | tenant_id    | tenant-a                                             |
    When the webhook consumer verifies the signature
    Then the consumer should compute HMAC-SHA256 of the payload using tenant secret
    And the computed signature should match the provided signature
    And the webhook should be processed successfully

  Scenario: Invalid HMAC signature rejection
    Given a webhook request is received with invalid signature
    When the webhook consumer verifies the signature
    Then the signature verification should fail
    And the webhook should be rejected with HTTP 401 Unauthorized
    And the request should be logged as potential security threat

  Scenario: Webhook event filtering by subscription
    Given tenant "tenant-b" is subscribed only to "order.created" events
    When a "product.updated" event occurs for tenant "tenant-b"
    Then no webhook should be sent to tenant "tenant-b"
    When an "order.created" event occurs for tenant "tenant-b"
    Then a webhook should be sent to tenant "tenant-b"

  Scenario: Webhook delivery retry on failure
    Given a webhook is configured for tenant "tenant-a"
    And the webhook endpoint returns HTTP 500 error
    When the webhook delivery fails
    Then the webhook should be retried with exponential backoff:
      | attempt | delay_seconds |
      | 1       | 1             |
      | 2       | 2             |
      | 3       | 4             |
      | 4       | 8             |
      | 5       | 16            |
    And each retry should include the same HMAC signature
    And the webhook status should be tracked for each attempt

  Scenario: Webhook delivery timeout handling
    Given a webhook endpoint takes longer than 30 seconds to respond
    When the webhook delivery times out
    Then the delivery should be marked as failed
    And the webhook should be retried according to retry policy
    And timeout should be logged for monitoring

  Scenario: Maximum retry attempts and dead letter handling
    Given a webhook has failed 5 times (maximum attempts)
    When the retry limit is reached
    Then the webhook should be moved to dead letter status
    And no further delivery attempts should be made
    And an alert should be generated for manual investigation
    And the failed webhook should be stored for later analysis

  Scenario: Webhook delivery success confirmation
    Given a webhook is sent to tenant "tenant-a"
    When the webhook endpoint returns HTTP 200 OK
    Then the webhook status should be marked as "delivered"
    And the delivery timestamp should be recorded
    And no further retry attempts should be made

  Scenario: Multiple webhook endpoints per tenant
    Given tenant "tenant-a" has multiple webhook endpoints:
      | url                               | events_subscribed |
      | https://api.companya.com/orders   | order.*          |
      | https://api.companya.com/products | product.*        |
    When an "order.created" event occurs
    Then webhook should be sent only to "https://api.companya.com/orders"
    And webhook should not be sent to the products endpoint

  Scenario: Webhook payload includes tenant context
    Given an order event occurs for tenant "tenant-a"
    When the webhook is delivered
    Then the payload should include tenant information:
      | field         | value     |
      | tenant_id     | tenant-a  |
      | event_id      | [uuid]    |
      | event_type    | order.created |
      | timestamp     | [iso8601] |
      | data          | [order_details] |

  Scenario: Webhook secret rotation
    Given tenant "tenant-a" updates their webhook secret from "old-secret" to "new-secret"
    When new events are generated after the secret change
    Then webhooks should be signed with the new secret "new-secret"
    And old webhook deliveries should continue with "old-secret" until completed
    And webhook consumers should handle the secret transition gracefully