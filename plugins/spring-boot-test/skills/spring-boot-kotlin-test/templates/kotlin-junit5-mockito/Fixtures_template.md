# Fixture Patterns (Kotlin + JUnit 5 + Mockito)

Choose the pattern that matches the scope of your test data.

---

## Pattern 1: Top-level factory functions (shared across test classes)

Use when the same entity is constructed in multiple test files. Put in a `Fixtures.kt` file alongside the tests.

```kotlin
package com.example.project

import java.math.BigDecimal

fun createUser(
    id: Int = 0,
    email: String = "user@example.com",
    name: String = "Test User",
    active: Boolean = true
) = UserEntity(id, email, name, active, "test", null)

fun createOrder(
    id: Long = 1L,
    userId: Int = 0,
    status: OrderStatus = OrderStatus.PENDING
) = OrderEntity(id, userId, status, "test")

fun createPayment(
    id: Long = 1L,
    orderId: Long = 1L,
    amount: BigDecimal = BigDecimal("99.99")
) = PaymentEntity(id, orderId, amount)
```

---

## Pattern 2: Builder companion object (complex object graphs)

Use when you need related objects built together (e.g. a user with orders, or a full hierarchy). Put in an `OrderTestBuilder.kt` file.

```kotlin
package com.example.project

data class OrderGraph(val user: UserEntity, val orders: List<OrderEntity>)

object OrderTestBuilder {

    fun getOrder(
        id: Long = 1L,
        status: OrderStatus = OrderStatus.PENDING,
        userId: Int = 0
    ) = OrderEntity(id, userId, status, "test")

    // Builds a complete graph in one call — useful for integration tests
    fun getUserWithOrders(): OrderGraph {
        val user = createUser(id = 1, email = "alice@example.com", name = "Alice")
        val orders = listOf(
            getOrder(1L, OrderStatus.CONFIRMED, user.id),
            getOrder(2L, OrderStatus.SHIPPED, user.id)
        )
        return OrderGraph(user, orders)
    }
}
```

Usage:

```kotlin
val graph = OrderTestBuilder.getUserWithOrders()
val single = OrderTestBuilder.getOrder(99L, OrderStatus.CANCELLED, 1)
```

---

## Pattern 3: Private helper functions (local to one test class)

Use for simple objects only needed within a single test class. Define as private functions at the bottom of the test file.

```kotlin
class PaymentServiceTest {

    // tests...

    private fun samplePayment(
        id: Long = 1L,
        amount: BigDecimal = BigDecimal("10.00")
    ) = PaymentEntity(id, 1L, amount)

    private fun sampleRequest() = PaymentCreateDto(1L, BigDecimal("10.00"))
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

```kotlin
val json = javaClass.getResourceAsStream("/fixtures/payment-client/success-response.json")!!
    .readBytes().toString(Charsets.UTF_8)
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

Always design factory functions so callers only specify what is relevant to the test:

```kotlin
// Good — intent is clear, only the relevant field is specified
val order = createOrder(status = OrderStatus.CANCELLED)

// Avoid — forces the reader to figure out which fields matter
val order = OrderEntity(1L, 0, OrderStatus.CANCELLED, "test")
```
