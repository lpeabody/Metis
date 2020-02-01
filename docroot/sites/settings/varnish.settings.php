<?php
/**
 * @file
 * Local varnish settings overrides.
 */

use Acquia\Blt\Robo\Common\EnvironmentDetector;

if (EnvironmentDetector::isLocalEnv() && getenv('DOCKSAL') && getenv('VIRTUAL_HOST')) {
  $host = getenv('VIRTUAL_HOST');
  $host_parts = explode('.', $host);
  $varnish_configs = [
    'varnish_purger.settings.63375491ff',
    'varnish_purger.settings.cafb995c3d',
  ];
  foreach ($varnish_configs as $varnish_config) {
    $host = getenv('VIRTUAL_HOST');
    $config[$varnish_config]['hostname'] = "varnish.$host";
    // The first header in the config MUST BE X-Acquia-Purge.
    $config[$varnish_config]['headers'][0]['value'] = $host_parts[0];
  }
}
