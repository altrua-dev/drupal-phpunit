# PHPUnit Setup Reference

Use this reference when setting up PHPUnit for Drupal 10/11 projects.

## Step 1 - Development dependencies

```bash
# The -W flag lets Composer update transitive development dependencies
# when the lock file pins testing packages to incompatible versions.
composer require --dev drupal/core-dev --with-all-dependencies
```

## Step 2 - Create a dedicated test DB user

`Drupal\Core\Database\Connection::createConnectionOptionsFromUrl()` uses `parse_url()` without calling `urldecode()` on the `pass` field: a password containing `#`, `=`, `;`, or `@` reaches PDO still encoded, resulting in `Access denied`. Always create a user with a simple password:

```sql
CREATE USER '<DB_TEST_USER>'@'<DB_HOST>' IDENTIFIED BY '<DB_TEST_PASS>';
GRANT ALL PRIVILEGES ON <DB_TEST_NAME>.* TO '<DB_TEST_USER>'@'<DB_HOST>';
FLUSH PRIVILEGES;
```

## Step 3 - Check for duplicate drupal/core installations

In projects using `installer-paths`, `drupal/core` is installed in `web/core/`, but Composer also keeps a copy in `vendor/drupal/core/`. The standard bootstrap resolves classes from the latter, `DrupalKernel::guessApplicationRoot()` calculates the wrong root, and Drupal loads `.module` files from both paths, resulting in `Cannot redeclare system_hook_info()`.

```bash
# Check whether the duplicate copy exists
ls vendor/drupal/core 2>/dev/null \
  && echo "DUPLICATE CORE - a custom bootstrap is required (see below)" \
  || echo "OK - use the standard bootstrap"
```

If the duplicate core exists, create a custom bootstrap. The path depends on where `phpunit.xml` will be placed.

### Option A - bootstrap in `web/tests/bootstrap.php`

Use this when `phpunit.xml` is in `web/`.

```php
<?php

// Custom bootstrap: redirect the classmap from vendor/drupal/core to web/core.
// Required when installer-paths produces a duplicate copy of drupal/core.
// __DIR__ = <root>/web/tests/ -> ../../vendor = <root>/vendor
$loader = require __DIR__ . '/../../vendor/autoload.php';

$fix = [];
foreach ($loader->getClassMap() as $class => $path) {
  if (str_contains($path, '/drupal/core/')) {
    $relative = substr($path, strpos($path, '/drupal/core/') + strlen('/drupal/core'));
    $fix[$class] = __DIR__ . '/../core' . $relative;  // -> web/core
  }
}
if (!empty($fix)) {
  $loader->addClassMap($fix);
}

$loader->addPsr4('Drupal\\Core\\', [__DIR__ . '/../core/lib/Drupal/Core'], TRUE);
$loader->addPsr4('Drupal\\Component\\', [__DIR__ . '/../core/lib/Drupal/Component'], TRUE);

require __DIR__ . '/../core/tests/bootstrap.php';
```

### Option B - bootstrap in `tests/bootstrap.php`

Use this when `phpunit.xml` is in the project root.

```php
<?php

// __DIR__ = <root>/tests/ -> ../vendor = <root>/vendor
$loader = require __DIR__ . '/../vendor/autoload.php';

$fix = [];
foreach ($loader->getClassMap() as $class => $path) {
  if (str_contains($path, '/drupal/core/')) {
    $relative = substr($path, strpos($path, '/drupal/core/') + strlen('/drupal/core'));
    $fix[$class] = __DIR__ . '/../web/core' . $relative;  // -> web/core
  }
}
if (!empty($fix)) {
  $loader->addClassMap($fix);
}

$loader->addPsr4('Drupal\\Core\\', [__DIR__ . '/../web/core/lib/Drupal/Core'], TRUE);
$loader->addPsr4('Drupal\\Component\\', [__DIR__ . '/../web/core/lib/Drupal/Component'], TRUE);

require __DIR__ . '/../web/core/tests/bootstrap.php';
```

## Step 4 - Copy and configure phpunit.xml

The location of `phpunit.xml` is a choice: the project root (more common in standard drupal-composer templates) or inside `web/` (simplifies relative paths to test directories).

Do not write `phpunit.xml.dist` from scratch. Copy Drupal Core's upstream `web/core/phpunit.xml.dist`, then modify only the required local/project values: `bootstrap`, `SIMPLETEST_BASE_URL`, `SIMPLETEST_DB`, optional output directories, and custom-module testsuite paths.

`phpunit.xml` contains local credentials (`SIMPLETEST_DB`, `SIMPLETEST_BASE_URL`) and must not be committed. Use the `.dist` pattern:

```bash
# 1. Create the template with placeholders to commit to the repository
#    Option A - project root
cp web/core/phpunit.xml.dist phpunit.xml.dist
# Ignore the local file in Git
echo "phpunit.xml" >> .gitignore

#    Option B - inside web/
cp web/core/phpunit.xml.dist web/phpunit.xml.dist
echo "web/phpunit.xml" >> .gitignore

# 2. Each developer copies .dist to the local file and sets their own values
cp phpunit.xml.dist phpunit.xml          # or: cp web/phpunit.xml.dist web/phpunit.xml

# 3. Writable simpletest directory
mkdir -p web/sites/simpletest
chmod 777 web/sites/simpletest
```

In the committed `.dist` file, use `<...>` placeholders instead of real values. Each developer replaces the placeholders in their local `phpunit.xml`.

The examples below show the relevant sections to preserve or adapt inside the copied upstream file; they are not a replacement for the full Drupal Core `phpunit.xml.dist`.

### Option A - `phpunit.xml` in the project root

```xml
<phpunit bootstrap="web/core/tests/bootstrap.php">
  <!-- With duplicate core: bootstrap="tests/bootstrap.php" (option B in step 3) -->

  <php>
    <env name="SIMPLETEST_BASE_URL" value="http://<SITE_HOST>"/>
    <env name="SIMPLETEST_DB" value="mysql://<DB_TEST_USER>:<DB_TEST_PASS>@<DB_HOST>/<DB_TEST_NAME>"/>
    <env name="BROWSERTEST_OUTPUT_DIRECTORY" value="<ABSOLUTE_PATH>/browser-output"/>
    <env name="SYMFONY_DEPRECATIONS_HELPER" value="disabled"/>
  </php>

  <testsuites>
    <testsuite name="unit">
      <directory>web/modules/custom/*/tests/src/Unit</directory>
    </testsuite>
    <testsuite name="kernel">
      <directory>web/modules/custom/*/tests/src/Kernel</directory>
    </testsuite>
    <testsuite name="functional">
      <directory>web/modules/custom/*/tests/src/Functional</directory>
    </testsuite>
    <testsuite name="functional-javascript">
      <directory>web/modules/custom/*/tests/src/FunctionalJavascript</directory>
    </testsuite>
  </testsuites>
</phpunit>
```

### Option B - `phpunit.xml` in `web/`

Testsuite directories omit the `web/` prefix.

```xml
<phpunit bootstrap="core/tests/bootstrap.php">
  <!-- With duplicate core: bootstrap="tests/bootstrap.php" (option A in step 3) -->

  <php>
    <env name="SIMPLETEST_BASE_URL" value="http://<SITE_HOST>"/>
    <env name="SIMPLETEST_DB" value="mysql://<DB_TEST_USER>:<DB_TEST_PASS>@<DB_HOST>/<DB_TEST_NAME>"/>
    <env name="BROWSERTEST_OUTPUT_DIRECTORY" value="<ABSOLUTE_PATH>/browser-output"/>
    <env name="SYMFONY_DEPRECATIONS_HELPER" value="disabled"/>
  </php>

  <testsuites>
    <testsuite name="unit">
      <directory>modules/custom/*/tests/src/Unit</directory>
    </testsuite>
    <testsuite name="kernel">
      <directory>modules/custom/*/tests/src/Kernel</directory>
    </testsuite>
    <testsuite name="functional">
      <directory>modules/custom/*/tests/src/Functional</directory>
    </testsuite>
    <testsuite name="functional-javascript">
      <directory>modules/custom/*/tests/src/FunctionalJavascript</directory>
    </testsuite>
  </testsuites>
</phpunit>
```

## Execution commands

All commands run from the **Drupal project root**. Adapt `-c` to `phpunit.xml` or `web/phpunit.xml`.

### Pre-deploy (all configured custom tests)

```bash
./vendor/bin/phpunit -c phpunit.xml --testdox
```

Optional skill helper (lives in the skill install path, not the Drupal repo). Resolve the script path in this order:

1. `.agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh` (project install)
2. `~/.agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh` (global install)

```bash
bash .agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh
```

The helper auto-detects `phpunit.xml` or `web/phpunit.xml`, uses `vendor/bin/phpunit`, and runs through DDEV when `.ddev/config.yaml` exists. Do not pass `--testdox` to the helper; it adds it automatically. Extra arguments pass through to PHPUnit:

```bash
bash .agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh --testsuite kernel
bash .agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh --group my_module
```

### Targeted runs

```bash
# Single test file
./vendor/bin/phpunit -c phpunit.xml web/modules/custom/module_name/tests/src/Kernel/MyTest.php --testdox

# All tests in one module
./vendor/bin/phpunit -c phpunit.xml web/modules/custom/module_name --testdox

# By @group annotation (add @group module_name to test classes)
./vendor/bin/phpunit -c phpunit.xml --group module_name --testdox

# By testsuite from phpunit.xml
./vendor/bin/phpunit -c phpunit.xml --testsuite unit --group module_name
./vendor/bin/phpunit -c phpunit.xml --testsuite kernel --group module_name
./vendor/bin/phpunit -c phpunit.xml --testsuite kernel --group module_name -v
```

For coverage reports and pre-commit guidance, see [testing-guide.md](testing-guide.md).
