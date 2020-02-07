# Metis

[![Build Status](https://travis-ci.com/lpeabody/Metis.svg?branch=master)](https://travis-ci.com/lpeabody/Metis)

[Metis](https://en.wikipedia.org/wiki/Metis_%28mythology%29) is a starter Drupal project meant to speed up
time-to-delivery by removing a lot of repetitive work that gets done time and time again. It is meant to provide
best-practice configurations, robust testing of all features, and sample content that showcases site features such as:

- Content Authoring
    - Layout Builder
    - Media Library
    - [Webform](https://www.drupal.org/project/webform)
- Images
    - [ImageMagick](https://www.drupal.org/project/imagemagick)
    - [Focal Point](https://www.drupal.org/project/focal_point)
- Translations
    - Content Translation
    - Configuration Translation
    - UI Translation
    - [Translation Management Tool](https://www.drupal.org/project/tmgmt)
        - Group translatable items into jobs and submit them to third parties for translation.
- Site Search
    - [Search API Solr](https://www.drupal.org/project/search_api_solr)
    - [Faceted Search](https://www.drupal.org/project/facets)
- SEO
    - [Google Tag Manager](https://www.drupal.org/project/google_tag)
    - [Schema.org JSON-LD](https://www.drupal.org/project/schema_metatag)
    - [Metatag](https://www.drupal.org/project/metatag)
        - Open Graph
        - Twitter Cards
    - [Sitemap XML](https://www.drupal.org/project/simple_sitemap)
    - [Robots.txt](https://www.drupal.org/project/robotstxt)
- Caching
    - [Purge](https://www.drupal.org/project/purge)
    - [Varnish Purging](https://www.drupal.org/project/varnish_purge)
- REST API
    - JSON:API endpoints for all entity types and bundles
- Configuration
    - Installation from configuration via profile
    - [Configuration Split](https://www.drupal.org/project/config_split)
    - [Config Ignore](https://www.drupal.org/project/config_ignore)
- Platform Readiness
    - Acquia
- Development
    - [Acquia BLT](https://docs.acquia.com/blt/)
    - [Default Content](https://www.drupal.org/project/default_content) (for providing starter content)
    - [Stage File Proxy](https://www.drupal.org/project/stage_file_proxy) (for retrieving missing local files from remote sites)
- Testing
    - Behat
    - PHPUnit
    - PHPCS Drupal coding standards
    - Drupal Check for D9 readiness

This project is optimized for running in a [Docksal](https://docksal.io/) environment. All project-related instructions
assume you are running a local Docksal environment. This does not preclude the possibility of adding support for
additional environments (i.e. Lando, Dev Desktop, DDEV, etc).

# Getting Started

This project is based on BLT, an open-source project template and tool that enables building, testing, and deploying Drupal installations following Acquia Professional Services best practices. While this is one of many methodologies, it is our recommended methodology. 

1. Review the [Required / Recommended Skills](https://docs.acquia.com/blt/developer/skills/) for working with a BLT project.
2. Ensure that your computer meets the minimum installation requirements (and then install the required applications). See the [System Requirements](https://docs.acquia.com/blt/install/).
3. Request access to organization that owns the project repo in GitHub (if needed).
4. Fork the project repository in GitHub.
5. Request access to the Acquia Cloud Environment for your project (if needed).
6. Setup a SSH key that can be used for GitHub and the Acquia Cloud (you CAN use the same key).
    1. [Setup GitHub SSH Keys](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)
    2. [Setup Acquia Cloud SSH Keys](https://docs.acquia.com/acquia-cloud/ssh/generate)
7. Clone your forked repository. By default, Git names this "origin" on your local.
    ```
    $ git clone git@github.com:<account>/Metis.git
    ```
8. To ensure that upstream changes to the parent repository may be tracked, add the upstream locally as well.
    ```
    $ git remote add upstream git@github.com:lpeabody/Metis.git
    ```

9. Update your the configuration located in the `/blt/blt.yml` file to match your site's needs. See [configuration files](#important-configuration-files) for other important configuration files.


----
# Setup Local Environment.

1. Clone the project.
2. Run `fin init`.
3. Run `fin uli` to generate a login link and automatically open it in your default browser.
4. Open http://docs.metis.docksal/ to view the local documentation.

---

# Resources 

Additional [BLT documentation](https://docs.acquia.com/blt/) may be useful. You may also access a list of BLT commands by running this:
```
$ blt
``` 

Note the following properties of this project:
* Primary development branch: develop
* Local environment: @docksal.default
* Local site URL: http://metis.docksal/

### Important Configuration Files

BLT uses a number of configuration (`.yml` or `.json`) files to define and customize behaviors. Some examples of these are:

* `blt/blt.yml` (formerly blt/project.yml prior to BLT 9.x)
* `blt/local.blt.yml` (local only specific blt configuration)
* `docroot/sites/default/blt.yml` (default site-specific BLT configuration)
* `drush/sites` (contains Drush aliases for this project)
* `composer.json` (includes required components, including Drupal Modules, for this project)

## Resources

* GitHub - https://github.com/lpeabody/Metis
* TravisCI - https://travis-ci.com/lpeabody/Metis
