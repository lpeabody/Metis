<?php
// $extra should be an array looking like
// [2, '--uri=...', '--no-interaction', '--ansi'] if invoked by BLT.
$uid = FALSE;
if (isset($extra) && is_array($extra)) {
  $uid = intval(reset($extra));
  $uid = is_int($uid) ? $uid : FALSE;
}

if (FALSE === $uid) {
  throw new \Exception("Passed UID was not an integer.");
}

$entity_types = ['node', 'paragraph'];
foreach ($entity_types as $entity_type) {
  $entity_ids = \Drupal::entityQuery($entity_type)->execute();
  /** @var \Drupal\Core\Entity\ContentEntityInterface $entities */
  $entities = \Drupal::entityTypeManager()->getStorage($entity_type)->loadMultiple($entity_ids);
  foreach ($entities as $entity) {
    $entity->uid = $uid;
    $entity->save();
  }
}
