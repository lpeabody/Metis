<?php

namespace ProjectBlt\Blt\Plugin\Commands;

use Acquia\Blt\Robo\BltTasks;
use Consolidation\AnnotatedCommand\CommandData;
use Acquia\Blt\Robo\Exceptions\BltException;

/**
 * This class defines example hooks.
 */
class DefaultContentCommand extends BltTasks {

  /**
   * This will execute after a site has been installed.
   *
   * @hook post-command internal:drupal:install
   */
  public function installDefaultContent($result, CommandData $commandData) {
    $dcm_path = $this->getConfigValue('default-content.path', NULL);
    if (is_string($dcm_path)) {
      $path_arguments = explode('/', $dcm_path);
      $default_content_module = end($path_arguments);
      $task = $this->taskDrush()
        ->stopOnFail()
        ->drush('cache-rebuild')
        ->drush('pm-enable')->arg($default_content_module)
        ->drush('pm-uninstall')->args('default_content')
        ->drush('cache-rebuild');
      $result = $task->run();
      if (!$result->wasSuccessful()) {
        throw new BltException("Failed to install default content.");
      }
    }
    else {
      $this->say("Skipping installation of default content since no module is defined.");
    }
  }

}
