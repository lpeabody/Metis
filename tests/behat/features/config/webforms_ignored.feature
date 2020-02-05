@config_ignore @webforms
Feature: Webforms are config ignored

  @api @javascript
  Scenario: Newly created webform is ignored
    Given I am logged in as a user with the Administrator role
    And I create a new webform entity with title "Test Webform Config Ignored"
    And I run drush "config-status"
    Then drush output should not contain "webform.webform.test_webform_config_ignored"

