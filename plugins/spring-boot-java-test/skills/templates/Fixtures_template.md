# Fixture Patterns

Choose the pattern that matches the scope of your test data.

---

## Pattern 1: Static factory methods (shared across test classes)

Use when the same entity is constructed in multiple test files. Put in a `Fixtures.java` file alongside the tests.

```java
package com.example.project;

import java.math.BigDecimal;

public final class Fixtures {

    private Fixtures() {}

    public static UserEntity createUser() {
        return createUser(0, "user@example.com", "Test User");
    }

    public static UserEntity createUser(int id, String email, String name) {
        return new UserEntity(id, email, name, true, "test", null);
    }

    public static OrderEntity createOrder() {
        return createOrder(1L, 0, OrderStatus.PENDING);
    }

    public static OrderEntity createOrder(long id, int userId, OrderStatus status) {
        return new OrderEntity(id, userId, status, "test");
    }

    public static PaymentEntity createPayment() {
        return createPayment(1L, 1L, new BigDecimal("99.99"));
    }

    public static PaymentEntity createPayment(long id, long orderId, BigDecimal amount) {
        return new PaymentEntity(id, orderId, amount);
    }
}
```

---

## Pattern 2: Builder (complex object graphs)

Use when you need related objects built together (e.g. a user with orders, or a full hierarchy). Put in a `OrderTestBuilder.java` file.

```java
package com.example.project;

import java.util.List;

public class OrderTestBuilder {

    public static OrderEntity getOrder() {
        return getOrder(1L, OrderStatus.PENDING, 0);
    }

    public static OrderEntity getOrder(long id, OrderStatus status, int userId) {
        return new OrderEntity(id, userId, status, "test");
    }

    // Builds a complete graph in one call — useful for integration tests
    public static OrderGraph getUserWithOrders() {
        var user = Fixtures.createUser(1, "alice@example.com", "Alice");
        var orders = List.of(
            getOrder(1L, OrderStatus.CONFIRMED, user.getId()),
            getOrder(2L, OrderStatus.SHIPPED, user.getId())
        );
        return new OrderGraph(user, orders);
    }

    public record OrderGraph(UserEntity user, List<OrderEntity> orders) {}
}
```

Usage:

```java
var graph = OrderTestBuilder.getUserWithOrders();
var single = OrderTestBuilder.getOrder(99L, OrderStatus.CANCELLED, 1);
```

---

## Pattern 3: Private helper methods (local to one test class)

Use for simple objects only needed within a single test class. Define as private static methods at the bottom of the test file.

```java
class PaymentServiceTest {

    // tests...

    private static PaymentEntity samplePayment() {
        return samplePayment(1L, new BigDecimal("10.00"));
    }

    private static PaymentEntity samplePayment(long id, BigDecimal amount) {
        return new PaymentEntity(id, 1L, amount);
    }

    private static PaymentCreateDto sampleRequest() {
        return new PaymentCreateDto(1L, new BigDecimal("10.00"));
    }
}
```

---

## Pattern 4: JSON fixture files (for client tests)

Store expected HTTP response bodies as files — never inline large JSON strings in test code.

**Location:** `src/test/resources/fixtures/clients/<client-name>/<scenario>.json`

```
src/test/resources/
└── fixtures/
    └── payment-client/
        ├── success-response.json
        └── error-response.json
```

**Reading in a test:**

```java
var json = new String(
    PaymentClientTest.class.getResourceAsStream("/fixtures/payment-client/success-response.json").readAllBytes(),
    StandardCharsets.UTF_8
);
```

**Example `success-response.json`:**

```json
{
  "payments": [
    { "id": "123", "amount": "99.99", "status": "COMPLETED" }
  ],
  "total": 1
}
```

---

## Key convention

Always design factory methods so callers only specify what is relevant to the test:

```java
// Good — intent is clear, only the relevant field is specified
var order = Fixtures.createOrder(1L, 0, OrderStatus.CANCELLED);

// Avoid — forces the reader to figure out which fields matter
var order = new OrderEntity(1L, 0, OrderStatus.CANCELLED, "test");
```
