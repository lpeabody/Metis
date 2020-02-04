@seo
Feature: Profile pages have validated schema

  Scenario: Validate profile page schema
    Given I am on "/test-person-profile"
    Then the schema type for the page is "Person"
    And the schema type has attribute "name" with value "Test Person"
