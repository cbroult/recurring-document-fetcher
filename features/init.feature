Feature: Initialize configuration
  As a user
  I want to generate a config file template
  So that I can configure my providers

  Scenario: Generate config file
    When I run `recurring-document-fetcher init -c test-config.yml`
    Then the exit status should be 0
    And the output should contain "Config file created"
    And a file named "test-config.yml" should exist

  Scenario: Refuse to overwrite existing config
    Given a file named "existing-config.yml" with:
      """
      providers: {}
      """
    When I run `recurring-document-fetcher init -c existing-config.yml`
    Then the exit status should be 1
    And the output should contain "already exists"
