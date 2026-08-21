# Parameterized Test Patterns

Use when the same assertion applies to multiple inputs. Choose based on how complex the input is.

---

## Pattern 1: `@CsvSource` (simple two-field cases)

Good for a handful of cases with primitive inputs where inline values are readable.

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;

class EmailValidatorTest {

    private final EmailValidator validator = new EmailValidator();

    @ParameterizedTest(name = "{2}")
    @CsvSource({
        "user@example.com,  true,  valid email",
        "'',               false, empty string is invalid",
        "notanemail,       false, missing @ is invalid",
        "@nodomain.com,    false, missing local part is invalid",
    })
    void validate(String input, boolean expectedValid, String description) {
        assertThat(validator.validate(input)).isEqualTo(expectedValid);
    }
}
```

---

## Pattern 2: `@MethodSource` (multi-field cases)

Use when cases have more than two fields or require objects. Define a static `Stream<Arguments>` method.

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.math.BigDecimal;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.params.provider.Arguments.arguments;

class PaymentAmountFormatterTest {

    private final PaymentAmountFormatter formatter = new PaymentAmountFormatter();

    @ParameterizedTest(name = "{0} {1} formats as {2}")
    @MethodSource("formatCases")
    void format(BigDecimal amount, String currency, String expected) {
        assertThat(formatter.format(amount, currency)).isEqualTo(expected);
    }

    static Stream<Arguments> formatCases() {
        return Stream.of(
            arguments(new BigDecimal("9.99"),   "EUR", "€9.99"),
            arguments(new BigDecimal("100.00"), "USD", "$100.00"),
            arguments(new BigDecimal("0.50"),   "GBP", "£0.50")
        );
    }
}
```

---

## Pattern 3: Record for complex rows

When a case has many fields, define a local record for the row type to avoid unreadable `Arguments` destructuring.

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

class OrderStatusServiceTest {

    private final OrderStatusService service = new OrderStatusService();

    record TransitionCase(String description, OrderStatus from, OrderStatus to, boolean expected) {}

    @ParameterizedTest(name = "{0}")
    @MethodSource("transitionCases")
    void canTransition(TransitionCase tc) {
        assertThat(service.canTransition(tc.from(), tc.to())).isEqualTo(tc.expected());
    }

    static Stream<TransitionCase> transitionCases() {
        return Stream.of(
            new TransitionCase("pending order can be confirmed",   OrderStatus.PENDING,    OrderStatus.CONFIRMED, true),
            new TransitionCase("confirmed order can be shipped",   OrderStatus.CONFIRMED,  OrderStatus.SHIPPED,   true),
            new TransitionCase("shipped order cannot go to PENDING", OrderStatus.SHIPPED,  OrderStatus.PENDING,   false)
        );
    }
}
```

---

## When to use which

| Situation | Pattern |
|-----------|---------|
| Simple primitive inputs, few cases | `@CsvSource` |
| Multiple fields or object inputs | `@MethodSource` with `Arguments` |
| Many fields and unreadable destructuring | `@MethodSource` with a local record |
