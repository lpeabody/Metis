<?php

namespace ProjectBlt\Blt\Plugin\Commands;

use Acquia\Blt\Robo\BltTasks;
use Acquia\Blt\Robo\Exceptions\BltException;

/**
 * Command class for refreshing a site's default content.
 *
 * Given the current site being operated against, this command will
 * export default content for that site to it's designated module specified by
 * BLT configuration value modules.default-content in the site's blt.yml.
 *
 * @package Acquia\Blt\Custom\Commands
 */
class RefreshDefaultContentCommand extends BltTasks {

  /** @var string Keyword for preserving default author. */
  const DEFAULT_AUTHOR_PRESERVE = 'preserve';

  /**
   * @var array
   *   Default content configuration for the current site.
   */
  protected $defaultContentConfig;

  /**
   * Initializer.
   *
   * @hook init custom:refresh-default-content
   */
  public function init() {
    $this->defaultContentConfig = $this->getConfigValue('default-content');
  }

  /**
   * Validate default content configuration.
   *
   * @hook validate custom:refresh-default-content
   *
   * @throws \Exception
   *   Exception stating the reason for failing validation.
   */
  public function validateConfig() {
    // Validate the site has default content configuration.
    if (empty($this->defaultContentConfig)) {
      throw new \Exception("No default content configuration exists for current site.");
    }

    // Validate the configuration specifies a valid path.
    if (isset($this->defaultContentConfig['path']) && !is_dir($this->defaultContentConfig['path'])) {
      throw new \Exception("Configured default content path is not a valid directory. Check the site's configuration.");
    }

    // Validate that default entities to export are given.
    if (empty($this->defaultContentConfig['default-entities']) || !is_array($this->defaultContentConfig['default-entities'])) {
      throw new \Exception("Default entities are not properly configured. Ensure entity types are listed.");
    }

    // Validate a proper default_author value is passed.
    if (isset($this->defaultContentConfig['default_author']) && $this->defaultContentConfig['default_author'] != self::DEFAULT_AUTHOR_PRESERVE) {
      if (!is_numeric($this->defaultContentConfig['default_author'])) {
        throw new \Exception("Assigned default_author value is not an integer. Assign to a valid UID.");
      }
    }
  }

  /**
   * Refresh default content for a given profile.
   *
   * @command custom:refresh-default-content
   *
   * @aliases rdc
   *
   * @description Refresh default content for a given profile.
   *
   * @throws \Acquia\Blt\Robo\Exceptions\BltException
   *   Thrown if there is a failure to accomplish the full task.
   */
  public function refreshDefaultContent() {
    // Get designated default content module for current site.
    $dcm_path = $this->defaultContentConfig['path'];

    if (!empty($dcm_path)) {
      // Get path to content directory of module.
      $content_folder = "$dcm_path/content";
      // Entities to export.
      $export_entities = $this->defaultContentConfig['default-entities'];

      // Error out if the module doesn't exist.
      if (!file_exists($dcm_path)) {
        throw new BltException("Specified default content module not found at $dcm_path.");
      }

      // At this point we have confirmed there is a valid location to export the
      // site content. Confirm with the user that they are aware that all
      // existing content will be deleted and replaced with what is on the
      // current local site instance.
      $confirmation = $this->confirm("This operation will delete the existing content export and replace with what is currently in the site. Continue?", TRUE);
      if (FALSE == $confirmation) {
        $this->logger->notice('Aborting export.');
        return 0;
      }

      // Re-create content directory.
      $this->_deleteDir($content_folder);
      $this->_mkdir($content_folder);
      $this->_touch("$content_folder/.gitkeep");

      if (self::DEFAULT_AUTHOR_PRESERVE !== $this->defaultContentConfig['default_author']) {
        // Set content to appropriate author prior to export.
        $this->setEntitiesWithAuthor($this->defaultContentConfig['default_author']);
      }

      // Export our content.
      $drush = $this->taskDrush()
        ->stopOnFail()
        ->verbose(TRUE)
        ->printOutput(TRUE);
      foreach ($export_entities as $entity_type) {
        $drush->drush('dcer')->arg($entity_type)->option('folder', $content_folder);
      }

      // Execute drush task.
      $result = $drush->run();
      if ($result->wasSuccessful()) {
        if ($this->defaultContentConfig['scrub_system_users'] === TRUE) {
          // Scrub users.
          $this->scrubUsers();
        }

        return 0;
      }
      else {
        throw new BltException("Drush failed to export content.");
      }
    }
    else {
      // Error out if no default module was specified for the current site in
      // BLT configuration.
      throw new BltException("No default content module specified for given site.");
    }
  }

  /**
   * Filter user 0 and user 1 out of the users folder.
   */
  protected function scrubUsers() {
    $content_folder = $this->defaultContentConfig['path'];
    // Currently scrub only anonymous and super admin accounts since these are
    // added by a new Drupal install always, which conflicts with Default
    // Content when attempting to import (throws error as content already
    // exists).
    $scrub_users_uids = [0, 1];
    $scrub_task = $this->taskFilesystemStack();
    foreach ($scrub_users_uids as $uid) {
      $uuid = $this->getUserUuid($uid);
      $scrub_task->remove("$content_folder/content/user/$uuid.json");
    }
    $scrub_task->run();
  }

  /**
   * Return the UUID of the user identified by uid.
   * @param $uid
   *   ID of the user to get the UUID of.
   *
   * @return string
   *   UUID of the passed user's uid.
   */
  protected function getUserUuid($uid) {
    $result = $this->taskDrush()
      ->printOutput(FALSE)
      ->drush('php:eval')
        ->arg("echo \Drupal\user\Entity\User::load($uid)->uuid->value;")
      ->run();
    $uuid = trim($result->getMessage());
    return $uuid;
  }

  /**
   * Sets the author for all content entities that reference an author.
   *
   * @throws \Acquia\Blt\Robo\Exceptions\BltException
   *   Thrown if the author could not be set on content.
   */
  protected function setEntitiesWithAuthor($uid = 2) {
    $blt_dir = $this->getConfigValue('repo.root') . '/blt';
    $result = $this->taskDrush()
      ->printOutput(TRUE)
      ->drush('php:script')
      ->rawArg("--script-path='$blt_dir/scripts' change-user -- $uid")
      ->run();
    if (!$result->wasSuccessful()) {
      throw new BltException("Failed to set the author on content.");
    }
  }

}
