<?php

namespace Drupal;

/**
 * Trait SpinTrait.
 *
 * Include in contexts that require you to wait for a result to appear before
 * proceeding.
 */
trait SpinTrait {

  /**
   * Spin until conditions are met, or until the number of tries are exceeded.
   *
   * @param callable $lambda
   *   The function that evaluates the condition.
   * @param int $tries
   *   The number of attempts that can be made before failure.
   *
   * @return bool
   *   TRUE if the condition has been met, FALSE otherwise.
   */
  protected function spin(callable $lambda, $tries = 60) {
    for ($i = 0; $i < $tries; $i++) {
      try {
        if ($lambda($this)) {
          return TRUE;
        }
      }
      catch (\Exception $e) {
        // Do nothing.
      }

      sleep(1);
    }
    return FALSE;
  }

}
