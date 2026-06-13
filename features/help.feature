Feature: CLI help
  As a user
  I want to see available commands
  So that I know how to use the tool

  Scenario: Show help
    When I run `recurring-document-fetcher help`
    Then the exit status should be 0
    And the output should contain "fetch"
    And the output should contain "version"

  Scenario: Show version
    When I run `recurring-document-fetcher version`
    Then the exit status should be 0
    And the output should contain "recurring-document-fetcher"
