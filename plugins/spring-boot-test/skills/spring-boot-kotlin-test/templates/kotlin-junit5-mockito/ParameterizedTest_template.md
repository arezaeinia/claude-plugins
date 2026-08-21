# Parameterized Test Patterns (Kotlin + JUnit 5 + Mockito)

Use when the same assertion applies to multiple inputs. Choose based on how complex the input is.

---

## Pattern 1: `@CsvSource` (simple two-field cases)

Good for a handful of cases with primitive inputs where inline values are readable.

```kotlin
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource

class EmailValidatorTest {

    private val validator = EmailValidator()

    @ParameterizedTest(name = "{2}")
    @CsvSource(
        "user@example.com,  true,  valid email",
        "'',               false, empty string is invalid",
        "notanemail,       false, missing @ is invalid",
        "@nodomain.com,    false, missing local part is invalid",
    )
    fun validate(input: String, expectedValid: Boolean, description: String) {
        assertThat(validator.validate(input)).isEqualTo(expectedValid)
    }
}
```

---

## Pattern 2: `@MethodSource` (multi-field cases)

Use when cases have more than two fields or require objects. Define a `@JvmStatic` method in a `companion object` returning `Stream<Arguments>`.

```kotlin
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.Arguments
import org.junit.jupiter.params.provider.MethodSource
import java.math.BigDecimal
import java.util.stream.Stream

class PaymentAmountFormatterTest {

    private val formatter = PaymentAmountFormatter()

    @ParameterizedTest(name = "{0} {1} formats as {2}")
    @MethodSource("formatCases")
    fun format(amount: BigDecimal, currency: String, expected: String) {
        assertThat(formatter.format(amount, currency)).isEqualTo(expected)
    }

    companion object {
        @JvmStatic
        fun formatCases(): Stream<Arguments> = Stream.of(
            Arguments.arguments(BigDecimal("9.99"),   "EUR", "€9.99"),
            Arguments.arguments(BigDecimal("100.00"), "USD", "$100.00"),
            Arguments.arguments(BigDecimal("0.50"),   "GBP", "£0.50")
        )
    }
}
```

---

## Pattern 3: Data class for complex rows

When a case has many fields, define a local `data class` for the row type to avoid unreadable `Arguments` destructuring.

```kotlin
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.MethodSource
import java.util.stream.Stream

class OrderStatusServiceTest {

    private val service = OrderStatusService()

    data class TransitionCase(val description: String, val from: OrderStatus, val to: OrderStatus, val expected: Boolean)

    @ParameterizedTest(name = "{0}")
    @MethodSource("transitionCases")
    fun canTransition(tc: TransitionCase) {
        assertThat(service.canTransition(tc.from, tc.to)).isEqualTo(tc.expected)
    }

    companion object {
        @JvmStatic
        fun transitionCases(): Stream<TransitionCase> = Stream.of(
            TransitionCase("pending order can be confirmed",     OrderStatus.PENDING,   OrderStatus.CONFIRMED, true),
            TransitionCase("confirmed order can be shipped",     OrderStatus.CONFIRMED, OrderStatus.SHIPPED,   true),
            TransitionCase("shipped order cannot go to PENDING", OrderStatus.SHIPPED,   OrderStatus.PENDING,   false)
        )
    }
}
```

---

## When to use which

| Situation | Pattern |
|-----------|---------|
| Simple primitive inputs, few cases | `@CsvSource` |
| Multiple fields or object inputs | `@MethodSource` with `Arguments` |
| Many fields and unreadable destructuring | `@MethodSource` with a local `data class` |
