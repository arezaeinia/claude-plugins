---
name: spring-boot-kotlin-test 
description: >
  Testing strategy and code templates for Kotlin/Spring Boot services.
  Use this skill whenever the user asks to write a test, what kind of test to write,
  wants a test class generated, asks about test structure, mentions controller/service/repository/client testing,
  references Kotest, MockK, DataJpaTest, MockMvc, or auth testing.
  Also use when the user says "write me a test for X", "add tests", "what should I test here", or
  pastes a class and asks for coverage. Invoke proactively when new production code is written without tests.
---

# Testing Strategy

This service follows the [Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html):
- **Unit tests**: fast, isolated, mock all dependencies — used for services and utilities
- **Integration tests**: hit a real Postgres TestContainer — used for repositories
- **Slice tests**: Spring context slices (`@WebMvcTest`) — used for controllers
- **Client tests**: WireMock (`@WireMockTest`) — used for outbound HTTP clients

---

## Step 0 — Detect project context

Before generating any test code, run the detection script from the project root to determine the language and test framework:

```bash
../../scripts/detect-project-context.sh
# or, if run from the project root:
<path-to-plugin>/scripts/detect-project-context.sh
```

The script outputs two lines:
```
LANGUAGE=<kotlin|java|mixed>
FRAMEWORK=<kotest-mockk|junit5-mockito>
```

Use the output to select the correct conventions and templates from the routing table below.

---

## Routing Table

| `LANGUAGE` | `FRAMEWORK` | Class under test | Conventions | Templates |
|---|---|---|---|---|
| `kotlin` | `kotest-mockk` | `.kt` | `refs/kotlin-kotest-mockk.md` | `templates/kotlin-kotest-mockk/` |
| `kotlin` | `junit5-mockito` | `.kt` | `refs/kotlin-junit5-mockito.md` | `templates/kotlin-junit5-mockito/` |
| `mixed` | `kotest-mockk` | `.kt` | `refs/kotlin-kotest-mockk.md` | `templates/kotlin-kotest-mockk/` |
| `mixed` | `junit5-mockito` | `.kt` | `refs/kotlin-junit5-mockito.md` | `templates/kotlin-junit5-mockito/` |
| `mixed` | any | `.java` | Use the `spring-boot-java-test` skill conventions | Java skill templates |

> **Mixed projects**: the class under test determines the output language. Check the file extension of the production class the user is asking to test. If it is `.java`, switch to the `spring-boot-java-test` skill for that test.

---

## Conventions and Templates

Read the ref file that matches your routing table row **before** generating any test code. Each ref file contains the framework-specific conventions and a table pointing to the exact template files to use.

- Kotest + MockK: `refs/kotlin-kotest-mockk.md`
- JUnit 5 + Mockito: `refs/kotlin-junit5-mockito.md`

---

## Running Tests

```bash
./mvnw test                          # all tests
./mvnw test -Dtest=MyServiceTest     # single class
./mvnw test -Dtest="MyService*"      # pattern
make test                            # format + build + test (pre-commit)
```
