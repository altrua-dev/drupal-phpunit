<a name="top"></a>
[![Altrua Drupal PHPUnit Skill](https://altrua.it/wp-content/uploads/2024/09/altrua_logo_color.svg)](https://altrua.it)
[![Drupal](https://img.shields.io/badge/Drupal-10%2C%2011%2B-0678BE)](https://www.drupal.org/docs/develop/automated-testing/phpunit-in-drupal)
[![agents](https://img.shields.io/badge/agents-Cursor%2C%20Claude%2C%20Codex-512BD4)](#installation)
[![test types](https://img.shields.io/badge/test_types-Unit%2C%20Kernel%2C%20Functional%2C%20JS-FF8C00)](#key-principles)
[![trigger](https://img.shields.io/badge/trigger-%2Fdrupal--phpunit-1D76DB)](#trigger)
[![by Altrua](https://img.shields.io/badge/by-Altrua-0078D4)](https://altrua.it)

# Drupal PHPUnit Skill

> As agents write more of our code, automated tests become the most practical way to verify behavior and catch regressions. This skill helps agents set up PHPUnit and write Drupal tests that actually hold up.

Reusable agent skill for configuring PHPUnit in Drupal 10/11+ projects and creating correct tests for custom modules.

Use it when an agent needs to:

- set up PHPUnit for a Drupal project;
- decide between `UnitTestCase`, `KernelTestBase`, `BrowserTestBase`, and `FunctionalJavascriptTestCase`;
- write tests for Drupal custom modules;
- debug common PHPUnit, bootstrap, database, or schema errors;
- avoid fragile over-mocking by using Drupal's real service container when appropriate.

## Trigger

```text
/drupal-phpunit
```

The skill can also be used whenever the user asks to write, configure, or debug Drupal tests.

## Contents

```text
drupal-phpunit/
├── SKILL.md
├── scripts/
│   └── run-drupal-tests.sh
└── references/
    ├── setup.md
    ├── skeletons.md
    └── troubleshooting.md
```

- `SKILL.md` is the main agent-facing guide: decision tree, core rules, setup checklist, and test creation workflow.
- `scripts/run-drupal-tests.sh` is an optional helper to run PHPUnit from any Drupal project. It stays in the skill install path, not in the project repo.
- `references/setup.md` contains the full PHPUnit setup flow, custom bootstrap notes, `phpunit.xml.dist` guidance, and execution commands.
- `references/skeletons.md` contains reusable test skeletons for Unit, Kernel, Functional, and shared base classes.
- `references/troubleshooting.md` maps common errors to causes and fixes.

## Key Principles

- Prefer `KernelTestBase` for custom module code that depends on Drupal services, entities, configuration, plugins, hooks, Field API, or database access.
- Use `UnitTestCase` only for pure PHP logic without Drupal API dependencies.
- Do not rewrite `phpunit.xml.dist` from scratch. Copy Drupal Core's upstream `web/core/phpunit.xml.dist`, then adjust the required project values.
- Keep repeated test setup DRY by extracting shared setup into a trait or module-specific base test class.
- Avoid over-mocking Drupal APIs when the real container gives a more reliable test.

## Installation

Copy this directory into the skills location used by your agent runtime.

Examples:

```text
~/.claude/skills/drupal-phpunit/
~/.cursor/skills/drupal-phpunit/
.agents/skills/drupal-phpunit/
```

The runtime must be able to read `SKILL.md` and the `references/` directory together.

## Usage Example

Ask the agent:

```text
/drupal-phpunit Configure PHPUnit for this Drupal 11 project and create kernel tests for my custom module.
```

Or:

```text
Write tests for the custom Drupal module in web/modules/custom/example_module.
```

The agent should first classify the test type, inspect module dependencies, set up missing schemas/configuration, and use the skeletons only when needed.

## Notes

This skill is intentionally agent-agnostic. The frontmatter and `/drupal-phpunit` trigger are compatible with agent systems that support skill-style Markdown instructions, while the content remains usable as plain documentation.
