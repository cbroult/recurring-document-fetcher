Feature: Handyvertrag.de provider
  As a user with a Handyvertrag.de mobile contract
  I want to fetch my invoices automatically
  So that I have them stored locally

  @browser
  Scenario: Fetch with Handyvertrag provider configured but missing credentials
    Given a file named "config.yml" with:
      """
      providers:
        handyvertrag:
          type: handyvertrag
          username: "015712345678"
      """
    When I run `recurring-document-fetcher fetch -c config.yml`
    Then the exit status should be 0
    And the output should contain "Fetching from handyvertrag"
    And the output should contain "Error"

  Scenario: Handyvertrag is listed as available provider type
    When I run `recurring-document-fetcher help`
    Then the exit status should be 0
    And the output should contain "fetch"
