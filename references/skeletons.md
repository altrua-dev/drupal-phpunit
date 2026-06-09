# Test Skeletons Reference

Use these skeletons when implementing Drupal custom module tests.

## UnitTestCase skeleton

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\module_name\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\module_name\ClassName;

/**
 * @coversDefaultClass \Drupal\module_name\ClassName
 * @group module_name
 */
class ClassNameTest extends UnitTestCase {

  protected ClassName $sut;

  protected function setUp(): void {
    parent::setUp();
    $this->sut = new ClassName();
  }

  /**
   * @covers ::methodName
   */
  public function testMethodName(): void {
    $result = $this->sut->methodName('input');
    $this->assertSame('expected', $result);
  }

}
```

Do not use `\Drupal::service()`, `\Drupal::entityTypeManager()`, the Entity API, `installEntitySchema()`, or database access. If you need them, use `KernelTestBase`.

## KernelTestBase skeleton

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\module_name\Kernel;

use Drupal\KernelTests\KernelTestBase;
use Drupal\node\Entity\Node;
use Drupal\node\Entity\NodeType;

/**
 * Tests ExampleService in the real Drupal container.
 *
 * @group module_name
 */
class ExampleServiceTest extends KernelTestBase {

  protected static $modules = [
    'system',
    'user',
    'field',
    'node',
    'module_name',
  ];

  protected function setUp(): void {
    parent::setUp();

    $this->installEntitySchema('user');
    $this->installEntitySchema('node');
    // $this->installSchema('module_name', ['table_name']);
    $this->installConfig(['system', 'node', 'module_name']);

    NodeType::create(['type' => 'article', 'name' => 'Article'])->save();
  }

  public function testServiceWorks(): void {
    /** @var \Drupal\module_name\ExampleService $service */
    $service = $this->container->get('module_name.example_service');

    $node = Node::create(['type' => 'article', 'title' => 'Test']);
    $node->save();

    $this->assertTrue($service->process($node));
  }

}
```

## BrowserTestBase skeleton

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\module_name\Functional;

use Drupal\Tests\BrowserTestBase;

/**
 * Tests module_name routing and forms.
 *
 * @group module_name
 */
class ExampleFormTest extends BrowserTestBase {

  protected static $modules = ['module_name'];

  protected $defaultTheme = 'stark';

  public function testFormAccessDenied(): void {
    $this->drupalGet('/admin/module-name/configuration');
    $this->assertSession()->statusCodeEquals(403);
  }

  public function testFormSubmission(): void {
    $admin = $this->drupalCreateUser(['administer module_name']);
    $this->drupalLogin($admin);

    $this->drupalGet('/admin/module-name/configuration');
    $this->assertSession()->statusCodeEquals(200);

    $this->submitForm(['field' => 'value'], 'Save');
    $this->assertSession()->pageTextContains('Configuration saved');
  }

}
```

## DRY pattern - Shared test base class

If multiple test classes repeat the same setup (bundle, field, entity, configuration):

```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\module_name\Kernel;

use Drupal\KernelTests\KernelTestBase;
use Drupal\node\Entity\NodeType;

abstract class ModuleNameKernelTestBase extends KernelTestBase {

  protected static $modules = [
    'system', 'user', 'field', 'node', 'module_name',
  ];

  protected function setUp(): void {
    parent::setUp();
    $this->installEntitySchema('user');
    $this->installEntitySchema('node');
    $this->installConfig(['system', 'node', 'module_name']);
    NodeType::create(['type' => 'article', 'name' => 'Article'])->save();
  }

}
```

Each test class extends `ModuleNameKernelTestBase` instead of `KernelTestBase`.
