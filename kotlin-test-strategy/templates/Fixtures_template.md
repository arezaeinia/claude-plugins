# Fixture Patterns

Choose the pattern that matches the scope of your test data.

---

## Pattern 1: Top-level functions (shared across test classes)

Use when the same entity is constructed in multiple test files. Put in a `Fixtures.kt` file alongside the tests.

```kotlin
package com.example.project

fun createUser(
    id: Int = 0,
    email: String = "user@example.com",
    name: String = "Test User",
    active: Boolean = true,
): UserEntity =
    UserEntity(
        id = id,
        email = email,
        name = name,
        active = active,
        createdBy = "test",
        updatedBy = null,
    )

fun createOrder(
    id: Long = 1L,
    userId: Int = 0,
    status: OrderStatus = OrderStatus.PENDING,
): OrderEntity =
    OrderEntity(
        id = id,
        userId = userId,
        status = status,
        createdBy = "test",
    )

fun createPayment(
    id: Long = 1L,
    orderId: Long = 1L,
    amount: BigDecimal = BigDecimal("99.99"),
): PaymentEntity =
    PaymentEntity(id = id, orderId = orderId, amount = amount)
```

---

## Pattern 2: Builder companion object (complex object graphs)

Use when you need related objects built together (e.g. a user with orders, or a full hierarchy). Put in a `SomethingTestBuilder.kt` file.

```kotlin
class OrderTestBuilder {
    companion object {
        fun getOrder(
            id: Long = 1L,
            status: OrderStatus = OrderStatus.PENDING,
            userId: Int = 0,
        ): OrderEntity =
            OrderEntity(
                id = id,
                status = status,
                userId = userId,
                createdBy = "test",
            )

        // Builds a complete graph in one call — useful for integration tests
        fun getUserWithOrders(): Pair<UserEntity, List<OrderEntity>> {
            val user = createUser(id = 1)
            val orders = listOf(
                getOrder(id = 1L, userId = user.id, status = OrderStatus.CONFIRMED),
                getOrder(id = 2L, userId = user.id, status = OrderStatus.SHIPPED),
            )
            return user to orders
        }
    }
}
```

Usage:

```kotlin
val (user, orders) = OrderTestBuilder.getUserWithOrders()
val single = OrderTestBuilder.getOrder(status = OrderStatus.CANCELLED)
```

---

## Pattern 3: Inline private helpers (local to one test class)

Use for simple objects only needed within a single test class. Define in a companion object or as private top-level functions at the bottom of the test file.

```kotlin
class PaymentServiceTest : FunSpec({
    // tests...
}) {
    companion object {
        private fun samplePayment(id: Long = 1L, amount: BigDecimal = BigDecimal("10.00")) =
            PaymentEntity(id = id, orderId = 1L, amount = amount)

        private fun sampleRequest(amount: BigDecimal = BigDecimal("10.00")) =
            PaymentCreateDto(orderId = 1L, amount = amount)
    }
}
```

---

## Pattern 4: JSON fixture files (for client tests)

Store expected HTTP response bodies as files — never inline large JSON strings in test code.

**Location:** `src/test/resources/fixtures/<client-name>/<scenario>.json`

```
src/test/resources/
└── fixtures/
    └── payment-client/
        ├── success-response.json
        └── error-response.json
```

**Reading in a test:**

```kotlin
val json = PaymentClientTest::class.java
    .getResource("/fixtures/payment-client/success-response.json")!!
    .readText()
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

Always use **default parameter values** so each test only specifies what is relevant to that case:

```kotlin
// Good — intent is clear, only the relevant field is specified
val order = createOrder(status = OrderStatus.CANCELLED)

// Avoid — forces the reader to figure out which fields matter
val order = OrderEntity(id = 1L, userId = 0, status = OrderStatus.CANCELLED, createdBy = "test")
```
