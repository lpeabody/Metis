#!/usr/bin/env bash

## Update all Composer packages and update Drupal configuration.
##
## Usage: fin platform-update

set -ev

composer install --no-interaction
/var/www/vendor/bin/blt setup --no-interaction
composer update --no-interaction
drush updb -y
drush cex -y
printf -v date '%(%Y-%m-%d--%Hh-%Mm-%Ss)T' -1
git checkout -b update/composer-update-$date
git add .
git commit -m "METIS-000: Composer and platform updates performed on $date." --no-verify
git push -u origin update/composer-update-$date
