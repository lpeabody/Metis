Feature: Profile pages have validated schema

  @api
  Scenario: Validate profile page schema
    Given I am on "/test-person-profile"
    Then the response status code should be 200
    Then the schema type for the page is "Person"
    And the schema type has attribute "name" with value "Test Person"
