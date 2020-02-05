<?php

/**
 * @file
 * Profile code for Metis.
 */

/**
 * Implements hook_config_ignore_settings_alter().
 */
function metis_config_ignore_settings_alter(array &$settings) {
  $settings[] = 'webform.webform.*';
}
