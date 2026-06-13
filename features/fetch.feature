Feature: Fetch documents
  As a user
  I want to fetch documents from providers
  So that I have my invoices locally

  Scenario: Fetch with no config file
    When I run `recurring-document-fetcher fetch -c /nonexistent/config.yml`
    Then the exit status should be 1
    And the output should contain "Config file not found"

  Scenario: Show version
    When I run `recurring-document-fetcher version`
    Then the exit status should be 0
    And the output should contain "recurring-document-fetcher"
