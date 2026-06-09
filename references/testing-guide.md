# Drupal Testing Guide

Use this reference when choosing test types, scaffolding tests, or planning coverage and pre-commit checks. For all PHPUnit run commands, see [setup.md](setup.md).

## Tests are required for production code

Custom module logic shipped to production should have automated tests. Tests define expected behavior, catch regressions, and give agents and reviewers a verifiable baseline.

## Test types

| Type | Base class | Use when |
|------|------------|----------|
| Unit | `UnitTestCase` | Isolated PHP logic with no Drupal bootstrap |
| Kernel | `KernelTestBase` | Services, entities, database, hooks, plugins |
| Functional | `BrowserTestBase` | Routes, forms, permissions, redirects, user flows |
| Functional JavaScript | `FunctionalJavascriptTestCase` | AJAX, dynamic forms, JavaScript behaviors |

`FunctionalJavascriptTestCase` extends Drupal's WebDriver test base. Reserve it for behavior that cannot be asserted without a real browser.

## Test directory layout

```text
my_module/
└── tests/
    └── src/
        ├── Unit/
        ├── Kernel/
        ├── Functional/
        └── FunctionalJavascript/
```

Namespaces follow the directory:

- `Drupal\Tests\my_module\Unit`
- `Drupal\Tests\my_module\Kernel`
- `Drupal\Tests\my_module\Functional`
- `Drupal\Tests\my_module\FunctionalJavascript`

Every test class should include `@group my_module` for targeted runs via `--group` in [setup.md](setup.md).

## When to write each type

- **Unit**: pure functions, value objects, data transformations, algorithms
- **Kernel**: injected services, entity CRUD, SQL through Drupal APIs, plugin discovery, hook implementations
- **Functional**: form submission, controller responses, access control, multi-step UI flows
- **Functional JavaScript**: behaviors that depend on JavaScript execution, AJAX callbacks, or WebDriver

Default for custom module business logic: **Kernel** unless the behavior is pure PHP or requires HTTP/JS.

## Scaffold tests with Drush

Prefer Drush generators for initial test files, then customize:

```bash
drush generate test:unit
drush generate test:kernel
drush generate test:browser
```

With DDEV:

```bash
ddev drush generate test:kernel
```

Review generated namespaces, `@group`, and `protected static $modules` before adding assertions. Implement assertions using [skeletons.md](skeletons.md) as a reference.

## Coverage (optional)

```bash
./vendor/bin/phpunit -c phpunit.xml --coverage-html coverage web/modules/custom/my_module
```

Adapt `-c` and paths to the project layout. See [setup.md](setup.md) for other run patterns.

## Pre-commit and CI

Before push, run the module test group using the commands in [setup.md](setup.md), for example:

```bash
./vendor/bin/phpunit -c phpunit.xml --group my_module --testdox
```

For Drupal 10/11 compatibility, run the same suite against both target core versions in CI when the project supports both.

## Official references

- [Drupal testing types](https://www.drupal.org/docs/develop/automated-testing/types-of-tests)
- [PHPUnit in Drupal](https://www.drupal.org/docs/develop/automated-testing/phpunit-in-drupal)
- [Drush generate test commands](https://www.drush.org/latest/commands/generate/)
