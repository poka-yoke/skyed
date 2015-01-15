Feature: Initialization

    In order to test proper init command behavior
    As an infrastructure developer using Skyed
    I want to setup my Skyed installation

    @wip
    Scenario: Running init with skyed already configured
        Given a mocked home directory
        And a file named ".skyed" with:
          """
          ---
          repo: "/Users/ifosch/projects/prova"
          branch: devel-e858cb83c97ddb3ee28e7c5b4a029065f0cdd025
          """
        When I run `skyed init`
        Then it should fail with exactly: 
          """
          error: Already initialized\n
          """
