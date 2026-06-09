---
name: drupal-phpunit
description: Configure PHPUnit on Drupal 10/11 and guide the creation of correct tests for custom modules. Trigger with /drupal-phpunit or when asked to write tests for Drupal.
---

# Drupal PHPUnit - Setup and Test Creation

Use this skill to configure PHPUnit for Drupal 10/11 projects and to create reliable tests for custom modules.

## Reference files

Read these only when needed:

- [references/setup.md](references/setup.md): PHPUnit setup, bootstrap, `phpunit.xml.dist`, and all execution commands.
- [references/testing-guide.md](references/testing-guide.md): test types, directory layout, Drush scaffolding, coverage, pre-commit, official links.
- [references/skeletons.md](references/skeletons.md): `UnitTestCase`, `KernelTestBase`, `BrowserTestBase`, and shared test base skeletons.
- [references/troubleshooting.md](references/troubleshooting.md): common setup and runtime failures.

## Core rules

**Production code needs tests**: custom module logic should ship with automated tests. See [references/testing-guide.md](references/testing-guide.md).

**DRY rule**: if `setUp()` repeats bundle/field/config/entity creation in 2+ test classes, create a shared trait or base class in the same module.

**Never over-mock**: if the code calls real Drupal services, use `KernelTestBase` with the real container, not fragile mocks.

**Do not rewrite `phpunit.xml.dist` from scratch**: copy Drupal Core's upstream `web/core/phpunit.xml.dist`, then modify only the required local/project values. See [references/setup.md](references/setup.md).

## Test type decision tree

For the full type matrix, directory layout, and `@group` conventions, read [references/testing-guide.md](references/testing-guide.md).

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

## Run tests

All PHPUnit commands and the optional skill helper script live in [references/setup.md](references/setup.md).

### Agent: when the user asks to run tests

1. `cd` to the Drupal project root (`vendor/bin/phpunit` must exist).
2. Follow [references/setup.md](references/setup.md): use direct PHPUnit or the skill helper from the installed skill path.
3. Wait for the command to finish. Running output with dots is not success until exit code is 0.
4. Report failures with the PHPUnit error message. If the run takes minutes, that is normal for kernel tests.

## 1. Initial PHPUnit setup

Follow the checklist in [references/setup.md](references/setup.md). Minimum steps:

1. `composer require --dev drupal/core-dev --with-all-dependencies`
2. Create a dedicated test database user with a simple password.
3. Check for duplicate `vendor/drupal/core/` and add a custom bootstrap if needed.
4. Copy `web/core/phpunit.xml.dist` to `phpunit.xml.dist` or `web/phpunit.xml.dist`.
5. Commit the `.dist` template only; each developer copies it locally and sets `SIMPLETEST_BASE_URL`, `SIMPLETEST_DB`, and output directories.

## 2. Test creation workflow for a custom module

### Step 1 - Inspect the module

```bash
find web/modules/custom/MODULE -name "*.php" | head -30
# Look for: services in services.yml, hooks in the .module file, plugins in src/Plugin,
# forms in src/Form, controllers in src/Controller, access handlers in src/Access
```

### Step 2 - Choose the test type

Use the decision tree above. Read [references/testing-guide.md](references/testing-guide.md) when you need the full matrix or naming conventions.

### Step 3 - Scaffold and implement

Scaffold with Drush when useful (`drush generate test:kernel`, and similar commands in [references/testing-guide.md](references/testing-guide.md)). Otherwise start from [references/skeletons.md](references/skeletons.md).

### Step 4 - Register the required modules

For Kernel and Functional tests, always include the module under test and the dependencies declared in its `.info.yml` file.

### Step 5 - Install schemas and configuration

For Kernel tests only:

```php
$this->installEntitySchema('node');            // For an entity type.
$this->installSchema('MODULE', ['table']);     // For custom DB tables.
$this->installConfig(['MODULE', 'system']);    // For YAML configuration.
```

### Step 6 - Run tests

Use [references/setup.md](references/setup.md) for pre-deploy, module-scoped, and single-file runs.

### Step 7 - If the test fails

1. Read the complete exception, not only the title.
2. Determine whether the problem is in the test setup or in the code under test.
3. Fix either the code or the test, never both at the same time.
4. Add an assertion for the discovered edge case.
5. For common failures, use [references/troubleshooting.md](references/troubleshooting.md).
