# Troubleshooting Reference

Use this reference when PHPUnit setup or Drupal tests fail.

| Error | Cause | Fix |
|---|---|---|
| `composer require` fails because of lock conflicts | Incompatible versions in the lock file | Add `--with-all-dependencies` (`-W`) |
| `Cannot redeclare system_hook_info()` | Duplicate drupal/core: `vendor/drupal/core/` + `web/core/` | Create `web/tests/bootstrap.php` or `tests/bootstrap.php` as described in `setup.md` |
| `Access denied for user` in the DSN | `parse_url()` does not decode the password; special characters remain encoded | Use a dedicated DB user with a simple password |
| `Class not found` | Autoload files are outdated | Run `composer dump-autoload` |
| `The "X" entity type does not exist` | Entity schema is not installed | Add `installEntitySchema('X')` |
| `Configuration object not found` | YAML configuration is not loaded | Add `installConfig(['module'])` |
| `Call to undefined method \Drupal::...` in Unit | Drupal API used in `UnitTestCase` | Switch to `KernelTestBase` |
| `SIMPLETEST_DB not set` | `phpunit.xml` was not loaded | Check `-c web/phpunit.xml` or `-c phpunit.xml` |
| Functional test connection fails | `SIMPLETEST_BASE_URL` is unreachable | Start the web server before the test |
| `DB table not found` | Custom table was not created | Add `installSchema('module', ['table'])` |
