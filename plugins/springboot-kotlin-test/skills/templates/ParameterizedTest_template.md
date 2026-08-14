# Parameterized Test Patterns

Use when the same assertion applies to multiple inputs. Choose based on how the results need to appear in the test report.

---

## Pattern 1: `forEach` loop (simple, most common)

Good for a handful of cases where inline readability matters more than individual test names in CI.

```kotlin
class OrderStatusServiceTest : FunSpec({
    val service = OrderStatusService()

    context("canTransition") {
        listOf(
            Triple("pending order can be confirmed", OrderStatus.PENDING, OrderStatus.CONFIRMED),
            Triple("confirmed order can be shipped", OrderStatus.CONFIRMED, OrderStatus.SHIPPED),
            Triple("shipped order can be delivered", OrderStatus.SHIPPED, OrderStatus.DELIVERED),
        ).forEach { (description, from, to) ->
            test(description) {
                service.canTransition(from, to) shouldBe true
            }
        }

        listOf(OrderStatus.SHIPPED, OrderStatus.DELIVERED, OrderStatus.CANCELLED).forEach { status ->
            test("$status order cannot transition back to PENDING") {
                service.canTransition(status, OrderStatus.PENDING) shouldBe false
            }
        }
    }
})
```

---

## Pattern 2: Kotest `withData` (named entries in CI report)

Use when each case should appear as a distinct named test in the build output. Requires `io.kotest:kotest-framework-datatest` on the test classpath.

```kotlin
import io.kotest.core.spec.style.FunSpec
import io.kotest.datatest.withData

data class ValidationCase(
    val input: String,
    val expectedValid: Boolean,
    val description: String,
)

class EmailValidatorTest : FunSpec({
    val validator = EmailValidator()

    context("validate") {
        withData(
            nameFn = { it.description },
            ValidationCase("user@example.com", true,  "valid email"),
            ValidationCase("",                 false, "empty string is invalid"),
            ValidationCase("notanemail",        false, "missing @ is invalid"),
            ValidationCase("@nodomain.com",     false, "missing local part is invalid"),
        ) { (input, expectedValid) ->
            validator.validate(input) shouldBe expectedValid
        }
    }
})
```

---

## Pattern 3: Local `data class` for multi-field rows

When a case has more than two fields, define a local `data class` inside the `context` block to avoid unreadable `Triple` destructuring.

```kotlin
class PaymentAmountFormatterTest : FunSpec({
    val formatter = PaymentAmountFormatter()

    context("format amount with currency") {
        data class Case(val amount: BigDecimal, val currency: String, val expected: String)

        listOf(
            Case(BigDecimal("9.99"),   "EUR", "€9.99"),
            Case(BigDecimal("100.00"), "USD", "$100.00"),
            Case(BigDecimal("0.50"),   "GBP", "£0.50"),
        ).forEach { (amount, currency, expected) ->
            test("$amount $currency formats as '$expected'") {
                formatter.format(amount, currency) shouldBe expected
            }
        }
    }
})
```

---

## When to use which

| Situation | Pattern |
|-----------|---------|
| Few cases, readability over report granularity | `forEach` loop |
| Each case needs its own named entry in CI output | `withData` |
| Row has 3+ fields and `Triple` would be unreadable | local `data class` + `forEach` |
