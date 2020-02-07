<?php

/**
 * @file
 * Global config split settings.
 *
 * This is in addition to BLT's config.settings.php.
 *
 * @see vendor/acquia/blt/settings/config.settings.php
 */

use Acquia\Blt\Robo\Common\EnvironmentDetector;

$config['config_split.config_split.acquia']['status'] = EnvironmentDetector::isAhEnv();
