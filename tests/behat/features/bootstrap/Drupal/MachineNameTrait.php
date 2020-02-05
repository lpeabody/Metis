<?php

namespace Drupal;

use Drupal\Core\Language\LanguageInterface;

/**
 * Class MachineNameTrait.
 *
 * Use for generating a machine name the way Drupal expects.
 */
trait MachineNameTrait {

  /**
   * Generates a machine name based on a value.
   *
   * @param string $value
   *   The value to convert to a machine name.
   *
   * @return string|string[]|null
   *   The resulting machine name.
   */
  protected function getMachineName($value) {
    $machine_name = \Drupal::transliteration()
      ->transliterate($value, LanguageInterface::LANGCODE_DEFAULT, '_');
    $machine_name = strtolower($machine_name);
    $machine_name = preg_replace('/[^a-z0-9_]+/', '_', $machine_name);
    return preg_replace('/_+/', '_', $machine_name);
  }

}
