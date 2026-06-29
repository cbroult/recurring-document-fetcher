Feature: Configure providers
  As a user
  I want to configure providers interactively
  So that I can set up document fetching without editing YAML manually

  Scenario: List available provider types
    When I run `recurring-document-fetcher configure --list`
    Then the exit status should be 0
    And the output should contain "handyvertrag"
    And the output should contain "--username: Mobile number (required)"

  Scenario: Configure with flags (non-interactive)
    When I run `recurring-document-fetcher configure handyvertrag -c test-config.yml -- --username "015712345678" --password "secret123"`
    Then the exit status should be 0
    And the output should contain "Configured"
    And the file "test-config.yml" should contain exactly:
      """
      ---
      providers:
        handyvertrag:
          type: handyvertrag
          username: '015712345678'
      """

  Scenario: Configure without config file creates one
    When I run `recurring-document-fetcher configure handyvertrag -c new-config.yml -- --username "015712345678" --password "secret123"`
    Then the exit status should be 0
    And a file named "new-config.yml" should exist

  Scenario: Configure with unknown provider type
    When I run `recurring-document-fetcher configure unknown_provider -c test-config.yml`
    Then the exit status should be 1
    And the output should contain "Unknown provider type"

  Scenario: Refuse re-configuration without --force
    Given a file named "test-config.yml" with:
      """
      providers:
        handyvertrag:
          type: handyvertrag
          username: "015712345678"
      """
    When I run `recurring-document-fetcher configure handyvertrag -c test-config.yml -- --username "new" --password "new"`
    Then the exit status should be 1
    And the output should contain "Provider 'handyvertrag' (handyvertrag) is already configured"
    And the output should contain "Please use --force to overwrite"

  Scenario: Re-configure with --force overwrites values
    Given a file named "test-config.yml" with:
      """
      providers:
        handyvertrag:
          type: handyvertrag
          username: "015712345678"
      """
    When I run `recurring-document-fetcher configure handyvertrag -c test-config.yml -f -- --username "new_user" --password "new_secret"`
    Then the exit status should be 0
    And the file "test-config.yml" should contain exactly:
      """
      ---
      providers:
        handyvertrag:
          type: handyvertrag
          username: new_user
      """

  Scenario: Re-configure with --force preserves unrelated providers
    Given a file named "test-config.yml" with:
      """
      providers:
        handyvertrag:
          type: handyvertrag
          username: old_user
        other_provider:
          type: some_provider
      """
    When I run `recurring-document-fetcher configure handyvertrag -c test-config.yml -f -- --username "new_user" --password "new_secret"`
    Then the exit status should be 0
    And the file "test-config.yml" should contain exactly:
      """
      ---
      providers:
        handyvertrag:
          type: handyvertrag
          username: new_user
        other_provider:
          type: some_provider
      """

  Scenario: Configure with custom download directory
    When I run `recurring-document-fetcher configure handyvertrag -c test-config.yml -- --username "user" --password "pass" --download-dir "/custom/path"`
    Then the exit status should be 0
    And the file "test-config.yml" should contain exactly:
      """
      ---
      providers:
        handyvertrag:
          type: handyvertrag
          username: user
          download_dir: "/custom/path"
      """
