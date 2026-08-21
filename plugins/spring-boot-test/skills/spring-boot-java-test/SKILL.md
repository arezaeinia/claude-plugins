---
name: spring-boot-java-test
description: >
  Testing strategy and code templates for Java/Spring Boot services.
  Use this skill whenever the user asks to write a test, what kind of test to write,
  wants a test class generated, asks about test structure, mentions controller/service/repository/client testing,
  references JUnit 5, Mockito, MockitoBean, DataJpaTest, MockMvc, or auth testing.
  Also use when the user says "write me a test for X", "add tests", "what should I test here", or
  pastes a class and asks for coverage. Invoke proactively when new production code is written without tests.
---

# Testing Strategy

This service follows the [Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html):
- **Unit tests**: fast, isolated, mock all dependencies — used for services and utilities
- **Integration tests**: hit a real Postgres TestContainer — used for repositories
- **Slice tests**: Spring context slices (`@WebMvcTest`) — used for controllers
- **Client tests**: WireMock (`@WireMockTest`) — used for outbound HTTP clients

**Default test framework**: JUnit 5 (`@Test`, `@Nested`, `@DisplayName`) with AssertJ assertions.  
**Default mock library**: Mockito (`@Mock`, `when(...).thenReturn(...)`, `verify(...)`) — use `@MockitoBean` for Spring slice tests (Spring Boot 3.4+).

---

## Step 0 — Detect project context

Before generating any test code, run the detection script from the project root:

```bash
<path-to-plugin>/scripts/detect-project-context.sh
```

The script outputs:
```
LANGUAGE=<kotlin|java|mixed>
FRAMEWORK=<kotest-mockk|junit5-mockito>
```

> **Mixed projects**: if `LANGUAGE=mixed` and the class under test is a `.kt` file, use the `spring-boot-kotlin-test` skill instead — it handles Kotlin class generation with the correct framework.

This skill is for pure Java projects and for testing `.java` classes in mixed projects.

---

## Templates

Read the relevant template file before generating test code. Each file is a ready-to-adapt Java example.

| Test type                     | Template file                             | When to use                                                                  |
|-------------------------------|-------------------------------------------|------------------------------------------------------------------------------|
| Controller (behaviour + auth) | `templates/ControllerTest_template.md`    | REST endpoints; two classes: one for behaviour, one for auth                 |
| Service                       | `templates/ServiceTest_template.md`       | Pure unit tests for service classes                                          |
| Repository                    | `templates/RepositoryTest_template.md`    | Integration tests against real Postgres via TestContainer                    |
| Client                        | `templates/ClientTest_template.md`        | Outbound HTTP clients using WireMock (`@WireMockTest`)                       |
| Fixtures                      | `templates/Fixtures_template.md`          | Test data helpers — read this before creating any fixture or builder         |
| Parameterized tests           | `templates/ParameterizedTest_template.md` | Multiple inputs against the same logic — `@ParameterizedTest` with `@MethodSource` |

---

## Key Conventions

### JUnit 5 structure
- Use `@Nested` + `@DisplayName("when ...")` to group related cases
- Use `@DisplayName("should ...")` on individual `@Test` methods for readable output
- Use `@BeforeEach` to reset mocks and shared state between tests
- Prefer AssertJ: `assertThat(result).isEqualTo(...)`, `assertThatThrownBy(...)`, `assertThat(list).hasSize(...)`

### Controller tests
- Two separate classes per controller: `XxxControllerTest` (behaviour) and `XxxControllerAuthTest` (security)
- Use `@MockitoBean` (Spring Boot 3.4+) for mocking service dependencies in `@WebMvcTest` slices
- Behaviour test excludes `SecurityAutoConfiguration` and `OAuth2ResourceServerAutoConfiguration`
- Auth test keeps security enabled; use `opaqueToken()` from `spring-security-test` to simulate scopes

### Service tests
- No Spring context — instantiate the class under test directly with `@ExtendWith(MockitoExtension.class)`
- Use `@InjectMocks` for the subject and `@Mock` for all dependencies
- Use `@Spy` when you need real logic on a collaborator with one method stubbed

### Repository tests
- Default to Postgres. If the project uses a different database, check `pom.xml` or `build.gradle` for the JDBC dependency and use the matching TestContainers image and driver
- If no container initializer exists in the project, create one — see `templates/RepositoryTest_template.md` for the Postgres template and the generic pattern for other databases
- Use `@DataJpaTest` + `@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)` + `@ContextConfiguration(initializers = XxxContainerInitializer.class)` — `Replace.NONE` prevents Spring from silently swapping the datasource with H2
- Clean up with `deleteAllInBatch()` in `@BeforeEach` — don't rely on `@Transactional` rollback alone
- Call `entityManager.clear()` after `persistAndFlush()` to force a real DB read on assertions
- Test DB constraints (unique keys, not-null) explicitly — these are the highest-value repository tests

### Parameterized tests
- Read `templates/ParameterizedTest_template.md` before writing tests that repeat the same assertion over multiple inputs
- Use `@ParameterizedTest` + `@MethodSource` for cases with multiple fields — define a static `Stream<Arguments>` method
- Use `@ParameterizedTest` + `@CsvSource` for simple two-field cases where inline values are readable
- Use a record or inner static class for the row type when a case has more than two fields

### Fixtures
- Read `templates/Fixtures_template.md` before creating any test data helper
- Pick the right scope: **static factory methods** in a shared `Fixtures.java` for data shared across test classes, **inner static builder** for complex object graphs, **private helper methods** for simple objects used only within one test class
- Always use **default-like patterns** (method overloads or builders) so callers only specify what matters for the test
- **JSON fixtures** for client test responses go in `src/test/resources/fixtures/clients/<client-name>/<scenario>.json` — never inline large JSON strings in test code

### Client tests
- Store JSON fixtures in `src/test/resources/fixtures/clients/<client-name>/<scenario>.json`
- Use `verify(getRequestedFor(...))` to assert the request was made
- Stubs reset automatically between tests — no manual reset needed with `@WireMockTest`
- **POST/PUT/PATCH**: load the full request body from a fixture file (`fixtures/clients/<client-name>/<operation>-request.json`) and use `withRequestBody(equalToJson(requestJson))` on both the stub and the verify call — stricter than field-by-field matching and keeps the contract in one place
- **GET**: no request body — omit `withRequestBody` entirely

---

## Running Tests

```bash
./mvnw test                              # all tests
./mvnw test -Dtest=UserServiceTest       # single class
./mvnw test -Dtest="UserService*"        # pattern
make test                                # format + build + test (pre-commit)
```
