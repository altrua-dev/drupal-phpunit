#!/usr/bin/env bash
# Optional skill helper: invoke from the skill install path, not from the Drupal repo.
# Example: bash ~/.agents/skills/drupal-phpunit/scripts/run-drupal-tests.sh
# Run with the shell cwd set to the Drupal project root.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run-drupal-tests.sh [phpunit options]

Runs all tests defined in the project phpunit.xml (custom module testsuites by default).

Examples:
  run-drupal-tests.sh
  run-drupal-tests.sh --testsuite kernel
  run-drupal-tests.sh --group my_module
  run-drupal-tests.sh web/modules/custom/my_module/tests/src/Kernel/MyTest.php

Environment:
  DRUPAL_PHPUNIT_CONFIG   Override config file (phpunit.xml or web/phpunit.xml)
  DRUPAL_PROJECT_ROOT     Override project root (default: current directory)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

PROJECT_ROOT="${DRUPAL_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

if [[ ! -f vendor/bin/phpunit ]]; then
  echo "Error: vendor/bin/phpunit not found. Run composer require --dev drupal/core-dev from the project root." >&2
  exit 1
fi

if [[ -n "${DRUPAL_PHPUNIT_CONFIG:-}" ]]; then
  PHPUNIT_CONFIG="$DRUPAL_PHPUNIT_CONFIG"
elif [[ -f phpunit.xml ]]; then
  PHPUNIT_CONFIG="phpunit.xml"
elif [[ -f web/phpunit.xml ]]; then
  PHPUNIT_CONFIG="web/phpunit.xml"
elif [[ -f phpunit.xml.dist ]]; then
  echo "Error: phpunit.xml not found. Copy phpunit.xml.dist to phpunit.xml and set local DB credentials." >&2
  exit 1
elif [[ -f web/phpunit.xml.dist ]]; then
  echo "Error: web/phpunit.xml not found. Copy web/phpunit.xml.dist to web/phpunit.xml and set local DB credentials." >&2
  exit 1
else
  echo "Error: no phpunit.xml or web/phpunit.xml found in $PROJECT_ROOT" >&2
  exit 1
fi

PHPUNIT_ARGS=("$@")
has_testdox=false
for arg in "${PHPUNIT_ARGS[@]}"; do
  if [[ "$arg" == "--testdox" ]]; then
    has_testdox=true
    break
  fi
done

PHPUNIT_CMD=(./vendor/bin/phpunit -c "$PHPUNIT_CONFIG")
if [[ "$has_testdox" == false ]]; then
  PHPUNIT_CMD+=(--testdox)
fi
PHPUNIT_CMD+=("${PHPUNIT_ARGS[@]}")

if [[ -f .ddev/config.yaml ]] && command -v ddev >/dev/null 2>&1; then
  ddev exec "${PHPUNIT_CMD[@]}"
else
  "${PHPUNIT_CMD[@]}"
fi
