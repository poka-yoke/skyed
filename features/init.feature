Feature: Initialization

    In order to test proper init command behavior
    As an infrastructure developer using Skyed
    I want to setup my Skyed installation

    @init
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

    @init
    Scenario: Running init for first time
        Given the default aruba timeout is 30 seconds
        And a mocked home directory
        And I set the environment variables to:
          | variable       | value        |
          | AWS_ACCESS_KEY | AKIAAKIAAKIA |
          | AWS_SECRET_KEY | sGe84ofDSkfo |
        And I run `git init test`
        And I cd to "test"
        And I run `git config user.email "test@test.com"`
        And I run `git config user.name "test"`
        And I run `touch file`
        And I run `git add file`
        And I run `git commit -m "file"`
        When I run `skyed init` interactively
        And I wait for output to contain "test"
        And I type ""
        Then the exit status should be 0
        And the file "../.skyed" should contain "tmp/aruba/test"
        And the file "../.skyed" should contain "devel-"
        And the file "../.skyed" should contain "AKIAAKIAAKIA"
        And the file "../.skyed" should contain "sGe84ofDSkfo"

    @init @wip
    Scenario: Running init for first time without AWS environment variables
        Given the default aruba timeout is 30 seconds
        And a mocked home directory
        And I set the environment variables to:
          | variable       | value        |
          | AWS_ACCESS_KEY |  |
          | AWS_SECRET_KEY |  |
        And I run `git init test`
        And I cd to "test"
        And I run `git config user.email "test@test.com"`
        And I run `git config user.name "test"`
        And I run `touch file`
        And I run `git add file`
        And I run `git commit -m "file"`
        When I run `skyed init` interactively
        And I wait for output to contain "test"
        And I type ""
        And I type "AKIAAKIAAKIA"
        And I type "sGe84ofDSkfo"
        Then the exit status should be 0
        And the file "../.skyed" should contain "tmp/aruba/test"
        And the file "../.skyed" should contain "devel-"
        And the file "../.skyed" should contain "AKIAAKIAAKIA"
        And the file "../.skyed" should contain "sGe84ofDSkfo"
