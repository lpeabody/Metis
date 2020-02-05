<?php

namespace Drupal;

use Drupal\Component\Utility\Random;
use Drupal\DrupalExtension\Context\RawDrupalContext;

/**
 * Class WebformContext.
 *
 * Provides helper steps for working with webforms.
 */
class WebformContext extends RawDrupalContext {

  use SpinTrait;
  use MachineNameTrait;

  /**
   * Tracks webforms that have been created in this context.
   *
   * Key/value pairs of machine_name and title.
   *
   * @var array
   */
  protected $webformEntitiesCreated;

  /**
   * The most recently referenced webform in this context.
   *
   * Array is a key/value pair of machine_name and title.
   *
   * @var array|null
   */
  protected $mostRecentWebform;

  /**
   * Constructor.
   *
   * Sets initial values for data members.
   */
  public function __construct() {
    $this->webformEntitiesCreated = [];
    $this->mostRecentWebform = NULL;
  }

  /**
   * Cleanup any entities that were created via steps.
   *
   * @AfterScenario
   */
  public function cleanup() {
    foreach ($this->webformEntitiesCreated as $machine_name => $title) {
      /** @var \Drupal\webform\Entity\Webform[] $webform */
      $webform = \Drupal::entityTypeManager()->getStorage('webform')->loadByProperties(['id' => $machine_name]);
      if (!empty($webform)) {
        $webform = reset($webform);
        $webform->delete();
      }
    }
  }

  /**
   * Interact with the browser to create a webform entity with optional title.
   *
   * @param string|null $title
   *   Optional title to use to create the webform. If no title is passed then
   *   a randomly generated title will be used.
   *
   * @Then I create a new webform entity
   */
  public function createNewWebform($title = NULL) {
    if (empty($title)) {
      $random = new Random();
      $title = $random->string(12);
    }
    $machine_name = $this->getMachineName($title);
    $this->visitPath('/admin/structure/webform');
    $this->assertSession()->statusCodeEquals(200);
    $this->getSession()->getPage()->clickLink('Add webform');
    $this->spin(function (WebformContext $context) {
      $this->assertSession()->fieldExists('Title');
    }, 5);
    $this->getSession()->getPage()->fillField('Title', $title);
    $has_machine_name = $this->spin(function (WebformContext $context) use ($machine_name) {
      $this->assertSession()->pageTextContains($machine_name);
      return TRUE;
    }, 5);
    if ($has_machine_name) {
      $this->getSession()->getPage()->pressButton('Save');
      $this->webformEntitiesCreated[$machine_name] = $title;
      $this->mostRecentWebform = [
        'title' => $title,
        'machine_name' => $machine_name,
      ];
    }
    else {
      var_dump($title, $machine_name);
      throw new \Exception('Machine name did not appear.');
    }
  }

  /**
   * Interact with the browser to create a webform entity with a title.
   *
   * @param string $title
   *   Title used to create the webform.
   *
   * @Then I create a new webform entity with title :title
   */
  public function createNewTitledWebform($title) {
    $this->createNewWebform($title);
  }

}
