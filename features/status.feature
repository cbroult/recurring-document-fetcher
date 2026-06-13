Feature: Download status
  As a user
  I want to see my download history
  So that I know which documents have been fetched

  Scenario: Status with no downloads
    When I run `recurring-document-fetcher status`
    Then the exit status should be 0
    And the output should contain "No downloads recorded"
