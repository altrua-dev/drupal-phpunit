---
name: drupal-phpunit
description: Configure PHPUnit on Drupal 10/11 and guide the creation of correct tests for custom modules. Trigger with /drupal-phpunit or when asked to write tests for Drupal.
---

# Drupal PHPUnit - Setup and Test Creation

Use this skill to configure PHPUnit for Drupal 10/11 projects and to create reliable tests for custom modules.

## Reference files

Read these only when needed:

- [references/setup.md](references/setup.md): full PHPUnit setup, custom bootstrap, `phpunit.xml.dist`, and execution commands.
- [references/skeletons.md](references/skeletons.md): `UnitTestCase`, `KernelTestBase`, `BrowserTestBase`, and shared test base skeletons.
- [references/troubleshooting.md](references/troubleshooting.md): common setup and runtime failures.

## Run all tests (pre-deploy)

From the **Drupal project root**, use the standard PHPUnit command:

```bash
./vendor/bin/phpunit -c phpunit.xml --testdox
```

Adapt `-c` to the project config: `phpunit.xml` or `web/phpunit.xml`.

Optional helper: this skill ships `scripts/run-drupal-tests.sh`. It does not live in the Drupal repo. Invoke it from the installed skill path while your shell is in the project root.

Resolve the script path in this order:

1. `.agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh` (project install)
2. `~/.agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh` (global install)

```bash
bash .agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh
```

The helper auto-detects `phpunit.xml` or `web/phpunit.xml`, uses `vendor/bin/phpunit`, and runs through DDEV when `.ddev/config.yaml` exists. Do not pass `--testdox` to the script; it already adds it. Extra arguments pass through to PHPUnit:

```bash
bash .agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh --testsuite kernel
bash .agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh --group my_module
```

### Agent: when the user asks to run tests

1. `cd` to the Drupal project root (`vendor/bin/phpunit` must exist).
2. Run the helper script from the resolved skill path above, or use direct PHPUnit.
3. Wait for the command to finish. Running output with dots is not success until exit code is 0.
4. Report failures with the PHPUnit error message. If the run takes minutes, that is normal for kernel tests.

## Core rules

**DRY rule**: if `setUp()` repeats bundle/field/config/entity creation in 2+ test classes, create a shared trait or base class in the same module.

**Never over-mock**: if the code calls real Drupal services, use `KernelTestBase` with the real container, not fragile mocks.

**Do not rewrite `phpunit.xml.dist` from scratch**: copy Drupal Core's upstream `web/core/phpunit.xml.dist`, then modify only the required local/project values. See [references/setup.md](references/setup.md).

## Test type decision tree

```
Is the logic pure PHP without any Drupal API?
  - YES: UnitTestCase

Does it depend on services, entities, hooks, plugins, the Field API, configuration, or DB queries?
  - YES: KernelTestBase  (default for custom modules)

Does it depend on HTTP routing, form submission, permissions, or redirects?
  - YES: BrowserTestBase

Does it require JS, AJAX, or real browser interaction?
  - YES: FunctionalJavascriptTestCase
```

## 1. Initial PHPUnit setup

For full setup details, read [references/setup.md](references/setup.md).

Minimum setup checklist:

1. Install Drupal development testing dependencies:

   ```bash
   composer require --dev drupal/core-dev --with-all-dependencies
   ```

2. Create a dedicated test database user with a simple password.

3. Check whether `vendor/drupal/core/` duplicates `web/core/`. If it does, use a custom bootstrap from [references/setup.md](references/setup.md).

4. Copy Drupal Core's `web/core/phpunit.xml.dist` to the chosen project template location:

   ```bash
   cp web/core/phpunit.xml.dist phpunit.xml.dist
   # or
   cp web/core/phpunit.xml.dist web/phpunit.xml.dist
   ```

5. Commit the `.dist` template with placeholders only. Do not commit local `phpunit.xml` credentials.

6. Each developer copies the `.dist` file to `phpunit.xml` or `web/phpunit.xml` and sets local values for `SIMPLETEST_BASE_URL`, `SIMPLETEST_DB`, and output directories.

## 2. Test creation workflow for a custom module

### Step 1 - Inspect the module

```bash
find web/modules/custom/MODULE -name "*.php" | head -30
# Look for: services in services.yml, hooks in the .module file, plugins in src/Plugin,
# forms in src/Form, controllers in src/Controller, access handlers in src/Access
```

### Step 2 - Identify the category

| What you are testing | Test type |
|---|---|
| Static method / pure calculation / value object | `UnitTestCase` |
| Custom service with DI / plugin / hook / entity CRUD | `KernelTestBase` |
| Form submission / route with HTTP response / redirect | `BrowserTestBase` |
| Interactive JS / AJAX / live chat | `FunctionalJavascriptTestCase` |

### Step 3 - Path and namespace

```
web/modules/custom/MODULE/tests/src/Unit/ClassNameTest.php
  -> namespace Drupal\Tests\MODULE\Unit;

web/modules/custom/MODULE/tests/src/Kernel/ClassNameTest.php
  -> namespace Drupal\Tests\MODULE\Kernel;

web/modules/custom/MODULE/tests/src/Functional/ClassNameTest.php
  -> namespace Drupal\Tests\MODULE\Functional;
```

### Step 4 - Implement the test

Use the skeletons in [references/skeletons.md](references/skeletons.md).

### Step 5 - Register the required modules

For Kernel and Functional tests, always include the module under test and the dependencies declared in its `.info.yml` file.

### Step 6 - Install schemas and configuration

For Kernel tests only:

```php
$this->installEntitySchema('node');            // For an entity type.
$this->installSchema('MODULE', ['table']);     // For custom DB tables.
$this->installConfig(['MODULE', 'system']);    // For YAML configuration.
```

### Step 7 - Run the test directly

All tests (pre-deploy), from the Drupal project root:

```bash
./vendor/bin/phpunit -c phpunit.xml --testdox
```

Optional helper from the installed skill path:

```bash
bash ~/.agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh
```

Single test file:

```bash
./vendor/bin/phpunit -c web/phpunit.xml path/to/Test.php --testdox
```

Adapt `-c` to the selected config path: `phpunit.xml` or `web/phpunit.xml`.

### Step 8 - If the test fails

1. Read the complete exception, not only the title.
2. Determine whether the problem is in the test setup or in the code under test.
3. Fix either the code or the test, never both at the same time.
4. Add an assertion for the discovered edge case.
5. For common failures, use [references/troubleshooting.md](references/troubleshooting.md).
