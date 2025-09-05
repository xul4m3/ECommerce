Feature: Dead Letter Handling
  As a system
  I want to handle failed operations with dead letter queues
  So that failures are tracked, analyzed, and can be manually resolved

  Background:
    Given the system is configured with dead letter handling
    And the following thresholds are configured:
      | operation_type    | max_retries | dead_letter_after |
      | webhook_delivery  | 5           | 5 failures        |
      | kafka_publish     | 3           | 3 failures        |
      | external_api_call | 5           | 5 failures        |
      | email_sending     | 3           | 3 failures        |

  Scenario: Webhook moved to dead letter after max retries
    Given a webhook delivery has failed 5 times
    And the maximum retry limit has been reached
    When the webhook processor runs again
    Then the webhook should be moved to the dead letter table
    And the webhook status should be changed to "dead_letter"
    And an alert should be generated for manual intervention
    And the original webhook data should be preserved for analysis

  Scenario: Dead letter queue structure and metadata
    Given a failed webhook is moved to dead letter
    Then the dead letter record should contain:
      | field              | description                           |
      | id                 | Unique dead letter record ID          |
      | original_id        | ID of the original failed operation   |
      | operation_type     | Type of operation (webhook, kafka, etc)|
      | tenant_id          | Tenant context for the operation      |
      | payload            | Original operation payload            |
      | error_messages     | Array of error messages from retries |
      | failure_count      | Total number of failures              |
      | first_failed_at    | Timestamp of first failure            |
      | dead_lettered_at   | Timestamp when moved to dead letter   |
      | status             | Current status (dead_letter, resolved)|

  Scenario: Dead letter queue monitoring and alerting
    Given operations are being moved to dead letter queues
    When dead letter entries are created
    Then monitoring alerts should be triggered:
      | alert_type           | condition                              |
      | high_dead_letter_rate| More than 10 entries per hour         |
      | tenant_specific_issues| More than 5 entries for single tenant |
      | critical_operation_failure| Payment or order operations fail  |
    And alerts should include dead letter entry details
    And operations teams should be notified immediately

  Scenario: Manual dead letter reprocessing
    Given there are dead letter entries in the queue
    And the underlying issues have been resolved
    When an operator manually triggers reprocessing of dead letter entry "DL-001"
    Then the system should extract the original operation data
    And attempt to reprocess the operation
    If reprocessing succeeds:
      Then the dead letter status should be updated to "resolved"
      And the operation should complete successfully
    If reprocessing fails:
      Then the dead letter should remain with updated error information

  Scenario: Bulk dead letter reprocessing
    Given there are multiple dead letter entries for the same failure cause:
      | id    | operation_type   | tenant_id | error_cause        |
      | DL-01 | webhook_delivery | tenant-a  | endpoint_timeout   |
      | DL-02 | webhook_delivery | tenant-a  | endpoint_timeout   |
      | DL-03 | webhook_delivery | tenant-b  | endpoint_timeout   |
    When the endpoint timeout issue is resolved
    And an operator triggers bulk reprocessing for "endpoint_timeout" errors
    Then all matching dead letter entries should be reprocessed
    And successful operations should be marked as "resolved"
    And any remaining failures should be updated with new error information

  Scenario: Dead letter queue retention and archival
    Given dead letter entries that are older than 90 days
    When the cleanup process runs
    Then resolved dead letter entries older than 90 days should be archived
    And unresolved entries should be retained regardless of age
    And archived data should be moved to long-term storage
    And operational database performance should be maintained

  Scenario: Dead letter analytics and reporting
    Given dead letter data is being collected over time
    When generating failure analysis reports
    Then reports should include:
      | metric                    | description                         |
      | failure_rate_by_operation | Failure rates grouped by operation type |
      | failure_rate_by_tenant    | Failure rates grouped by tenant    |
      | common_error_patterns     | Most frequent error messages/causes |
      | time_to_resolution        | Average time to resolve dead letters|
      | reprocessing_success_rate | Success rate of manual reprocessing |
    And trends should be identified to prevent future failures

  Scenario: Dead letter escalation for critical operations
    Given a critical operation like payment processing fails
    When the operation is moved to dead letter
    Then an immediate high-priority alert should be triggered
    And the operations team should be notified via multiple channels
    And the dead letter entry should be flagged as "critical"
    And automatic escalation should occur if not resolved within 1 hour

  Scenario: Dead letter tenant isolation
    Given dead letter entries exist for multiple tenants
    When tenant "tenant-a" admin requests dead letter information
    Then they should only see dead letters for "tenant-a"
    And cross-tenant dead letter data should not be accessible
    And tenant-specific reprocessing should be supported

  Scenario: Dead letter integration with monitoring systems
    Given external monitoring systems are configured
    When dead letter entries are created
    Then metrics should be exported to monitoring systems:
      | system      | metric_type        | metric_name                  |
      | Prometheus  | Counter            | dead_letter_entries_total    |
      | Prometheus  | Gauge              | dead_letter_queue_size       |
      | Grafana     | Dashboard          | Dead Letter Queue Health     |
      | PagerDuty   | Alert              | Critical Operation Failures  |
    And alerts should integrate with incident management workflows

  Scenario: Dead letter prevention through proactive monitoring
    Given failure patterns are being monitored
    When failure rates approach dead letter thresholds
    Then proactive alerts should be triggered before operations reach dead letter
    And automatic remediation should be attempted where possible
    And degraded service modes should be activated to prevent further failures

  Scenario: Dead letter audit trail
    Given dead letter operations are being performed
    When any action is taken on dead letter entries
    Then an audit trail should be maintained:
      | action_type      | tracked_information                    |
      | entry_created    | Original failure details and timestamp |
      | reprocessing_attempted | Who, when, and result              |
      | status_changed   | From/to status and reason              |
      | bulk_operations  | Scope and results of bulk actions      |
    And audit logs should be immutable and tamper-proof

  Scenario: Dead letter recovery strategies
    Given different types of failures require different recovery approaches:
      | failure_type          | recovery_strategy                    |
      | network_timeout       | Automatic retry with backoff         |
      | authentication_error  | Manual credential update required    |
      | rate_limit_exceeded   | Delayed automatic retry              |
      | data_corruption       | Manual data correction required      |
      | service_unavailable   | Wait for service recovery            |
    When dead letter entries are processed
    Then the appropriate recovery strategy should be applied
    And manual intervention should be requested only when necessary