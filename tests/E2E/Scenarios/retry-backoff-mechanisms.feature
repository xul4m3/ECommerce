Feature: Retry and Backoff Mechanisms
  As a system
  I want to implement robust retry and backoff mechanisms
  So that transient failures are handled gracefully and system resilience is maintained

  Background:
    Given the system is configured with retry and backoff mechanisms
    And the following services are available:
      | service_name    | status    |
      | PostgreSQL      | available |
      | Redis           | available |
      | Kafka           | available |
      | External_API    | unstable  |

  Scenario: HTTP client retry with exponential backoff
    Given an external API endpoint is temporarily unavailable
    When I make an HTTP request to the external API
    Then the request should be retried with exponential backoff:
      | attempt | delay_seconds | total_elapsed |
      | 1       | 0             | 0             |
      | 2       | 1             | 1             |
      | 3       | 2             | 3             |
      | 4       | 4             | 7             |
      | 5       | 8             | 15            |
    And each retry should include the original request headers
    And the total retry time should not exceed 30 seconds

  Scenario: Database connection retry on transient failure
    Given PostgreSQL is temporarily unavailable
    When I attempt a database operation
    Then the operation should be retried with exponential backoff
    And connection pooling should handle retry attempts
    And if all retries fail, a database unavailable error should be thrown
    When PostgreSQL becomes available again
    Then the next retry attempt should succeed

  Scenario: Kafka producer retry on broker unavailability
    Given Kafka broker is temporarily unavailable
    When I publish an event to Kafka
    Then the producer should retry with exponential backoff
    And the event should be queued locally during retries
    And if maximum retries are reached, the event should be saved to outbox
    When Kafka becomes available
    Then queued events should be published successfully

  Scenario: Redis operation retry with circuit breaker
    Given Redis is experiencing intermittent failures
    When I perform cache operations
    Then operations should be retried up to 3 times
    And if failure rate exceeds 50% in 1 minute
    Then the circuit breaker should open
    And subsequent cache operations should fail fast
    And operations should fallback to database
    When Redis stabilizes and circuit breaker timeout expires
    Then the circuit breaker should close and caching should resume

  Scenario: Webhook delivery retry with jitter
    Given a webhook endpoint is returning HTTP 503 errors
    When a webhook delivery fails
    Then it should be retried with exponential backoff plus jitter:
      | attempt | base_delay | jitter_range | max_delay |
      | 1       | 1s         | ±0.1s        | 1.1s      |
      | 2       | 2s         | ±0.2s        | 2.2s      |
      | 3       | 4s         | ±0.4s        | 4.4s      |
      | 4       | 8s         | ±0.8s        | 8.8s      |
      | 5       | 16s        | ±1.6s        | 17.6s     |
    And jitter should prevent thundering herd effects
    And webhook status should be tracked for each attempt

  Scenario: Partial failure retry with selective operations
    Given a batch operation with mixed success/failure results
    When processing a batch of 10 items and 3 fail
    Then only the 3 failed items should be retried
    And successful items should not be reprocessed
    And retry attempts should be tracked per item
    And if individual items reach max retries, they should be marked as failed

  Scenario: Timeout-based retry configuration
    Given different operation types have different timeout requirements:
      | operation_type | timeout_seconds | max_retries |
      | database_query | 5               | 3           |
      | cache_access   | 1               | 2           |
      | http_api_call  | 10              | 5           |
      | file_upload    | 30              | 3           |
    When operations timeout
    Then retries should respect the specific timeout and retry limits
    And appropriate error messages should be returned when limits are exceeded

  Scenario: Retry with different strategies per failure type
    Given different failure types require different retry strategies:
      | failure_type          | strategy           | max_retries |
      | network_timeout       | exponential_backoff| 5           |
      | rate_limit_exceeded   | fixed_interval     | 10          |
      | authentication_failed | no_retry           | 0           |
      | server_error_500      | exponential_backoff| 3           |
      | bad_request_400       | no_retry           | 0           |
    When different types of failures occur
    Then the appropriate retry strategy should be applied
    And non-retryable errors should fail immediately

  Scenario: Concurrent request retry coordination
    Given multiple concurrent requests to the same failing service
    When requests fail simultaneously
    Then retry attempts should be coordinated to prevent system overload
    And exponential backoff should include jitter to spread retry timing
    And circuit breaker state should be shared across all requests
    And successful retries should benefit all pending requests

  Scenario: Retry metrics and monitoring
    Given retry mechanisms are in operation
    When retries occur across the system
    Then retry metrics should be collected:
      | metric_name           | description                    |
      | retry_attempts_total  | Total number of retry attempts |
      | retry_success_rate    | Percentage of successful retries|
      | retry_exhaustion_rate | Percentage of operations that exhausted retries |
      | average_retry_delay   | Average delay between retries  |
    And alerts should be triggered when retry rates exceed thresholds
    And dashboards should show retry health across services

  Scenario: Graceful degradation on retry exhaustion
    Given all retry attempts have been exhausted for a critical service
    When the service remains unavailable
    Then the system should enter graceful degradation mode
    And alternative code paths should be activated where possible
    And users should receive appropriate error messages
    And system should continue to serve cached or default data
    And recovery should be automatic when the service becomes available

  Scenario: Backoff configuration per environment
    Given different environments have different retry requirements:
      | environment | base_delay_ms | max_delay_ms | max_retries |
      | development | 100           | 1000         | 3           |
      | staging     | 500           | 5000         | 5           |
      | production  | 1000          | 30000        | 7           |
    When retries occur in each environment
    Then the environment-specific configuration should be applied
    And production should have more aggressive retry policies
    And development should fail fast for debugging