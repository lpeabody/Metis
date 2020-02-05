<?php

namespace Drupal;

use Behat\Mink\Exception\UnsupportedDriverActionException;
use Drupal\DrupalExtension\Context\RawDrupalContext;

/**
 * FeatureContext class defines custom step definitions for Behat.
 */
class FeatureContext extends RawDrupalContext {

  use SpinTrait;

  /**
   * The number of screenshots taken so far.
   *
   * @var int
   */
  protected $screenshotCount;

  /**
   * Every scenario gets its own context instance.
   *
   * You can also pass arbitrary arguments to the
   * context constructor through behat.yml.
   */
  public function __construct() {
    $this->screenshotCount = 0;
  }

  /**
   * Resize the window to more sensible default.
   *
   * @BeforeScenario
   */
  public function resizeWindow() {
    try {
      $this->getSession()->resizeWindow(1440, 900, 'current');
    }
    catch (UnsupportedDriverActionException $e) {
      // Deal with it I guess.
    }
  }

  /**
   * Takes a screenshot.
   *
   * @param string $filename
   *   (optional) Ignored. The filename is based on a counter and prefixed with
   *   the name of the Mink browser.
   * @param mixed $filepath
   *   (optional) Ignored. The screenshot is saved in the directory above the
   *   Drupal root.
   *
   * @When I take a screenshot
   */
  public function saveScreenshot($filename = NULL, $filepath = NULL) {
    $filename = sprintf('%s_%d.png', $this->getMinkParameter('browser_name'), ++$this->screenshotCount);
    $filepath = \Drupal::root() . '/../';
    parent::saveScreenshot($filename, $filepath);
  }

}
