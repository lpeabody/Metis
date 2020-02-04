<?php

namespace Drupal;

use Drupal\DrupalExtension\Context\RawDrupalContext;
use ML\JsonLD\JsonLD;

/**
 * FeatureContext class defines custom step definitions for Behat.
 */
class SchemaContext extends RawDrupalContext {

  protected const MISSING_JSONLD_MESSAGE = 'There is no JSON-LD object loaded on the page.';

  /**
   * The last referenced schema type on the page.
   *
   * @var string
   */
  protected $lastReferencedType;

  /**
   * Every scenario gets its own context instance.
   *
   * You can also pass arbitrary arguments to the
   * context constructor through behat.yml.
   */
  public function __construct() {
    $this->lastReferencedType = '';
  }

  /**
   * Verify page is associated with a specific schema typa.
   *
   * @Then the schema type for the page is :schema_type
   */
  public function theSchemaTypeForThePageIs($schema_type) {
    $this->lastReferencedType = $schema_type;
    $jsonld_script = $this->getSession()->getPage()->find('xpath', '//script[@type="application/ld+json"]');
    if (!empty($jsonld_script)) {
      $document = JsonLD::getDocument($jsonld_script->getHtml());
      $graph = $document->getGraph();
      $nodes = $graph->getNodesByType('http://schema.org/' . $schema_type);
      if (empty($nodes)) {
        throw new \Exception('Schema type of "' . $schema_type . '" not found on page.');
      }
    }
    else {
      throw new \Exception(self::MISSING_JSONLD_MESSAGE);
    }
  }

  /**
   * Verify last referenced schema type has a property with a value.
   *
   * @Then the schema type has attribute :property with value :value
   */
  public function theSchemaTypeHasAttributeWithValue($property, $value) {
    $jsonld_script = $this->getSession()->getPage()->find('xpath', '//script[@type="application/ld+json"]');
    if (!empty($jsonld_script)) {
      $document = JsonLD::getDocument($jsonld_script->getHtml());
      $graph = $document->getGraph();
      $nodes = $graph->getNodesByType('http://schema.org/' . $this->lastReferencedType);
      foreach ($nodes as $node) {
        $properties = $node->getProperties();
        $property_name = 'http://schema.org/' . $property;
        if (!empty($properties[$property_name])) {
          /** @var \ML\JsonLD\TypedValue $typed_value */
          $typed_value = $properties[$property_name];
          $target_value = $typed_value->getValue();
          if ($target_value == $value) {
            return;
          }
          throw new \Exception("Property '$property' was found, but had value '$target_value' instead of '$value'.");
        }
      }
      throw new \Exception("Property '$property' was not found in the JSON-LD page object.");
    }
    throw new \Exception(self::MISSING_JSONLD_MESSAGE);
  }

}
