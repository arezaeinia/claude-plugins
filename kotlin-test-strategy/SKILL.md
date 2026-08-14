---
name: kotlin-test-strategy
description: >
  Testing strategy and code templates for this Kotlin/Spring Boot service.
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
- **Client tests**: `MockRestServiceServer` — used for outbound HTTP clients

**Default test framework**: Kotest `FunSpec` with `SpringExtension` for all test types.  
**Default mock library**: MockK (`mockk()`, `every {}`, `verify {}`) — avoid Mockito in new tests.

---

## Templates

Read the relevant template file before generating test code. Each file is a ready-to-adapt Kotlin example.

| Test type                     | Template file                          | When to use                                                                    |
|-------------------------------|----------------------------------------|--------------------------------------------------------------------------------|
| Controller (behaviour + auth) | `templates/ControllerTest_template.md` | REST endpoints; two classes: one for behaviour, one for auth                   |
| Service                       | `templates/ServiceTest_template.md`    | Pure unit tests for service classes                                            |
| Repository                    | `templates/RepositoryTest_template.md` | Integration tests against real Postgres via TestContainer                      |
| Client                        | `templates/ClientTest_template.md`     | Outbound HTTP clients using `MockRestServiceServer`                            |
| Fixtures                      | `templates/Fixtures_template.md`         | Test data helpers — read this before creating any fixture, builder, or JSON file |
| Parameterized tests           | `templates/ParameterizedTest_template.md` | Multiple inputs against the same logic — `forEach` loop or Kotest `withData`   |

---

## Key Conventions

### FunSpec structure
- Use `context("when ...")` to group related cases, `test("should ...")` for individual assertions
- For pure unit tests (no Spring): use lambda syntax `FunSpec({ ... })`
- For Spring-injected tests: use class body syntax `FunSpec()` with `@ApplyExtension(SpringExtension::class)` and an `init {}` block
- `clearAllMocks()` in `beforeTest` / `beforeEach` to prevent state leaking between tests
- Prefer Kotest matchers: `shouldBe`, `shouldContain`, `shouldHaveSize`, `shouldThrow`

### Controller tests
- Two separate classes per controller: `XxxControllerTest` (behaviour) and `XxxControllerAuthTest` (security)
- Use `@MockkBean` from `com.ninjasquad.springmockk` for mocking service dependencies in `@WebMvcTest` slices
- Behaviour test excludes `SecurityAutoConfiguration` and `OAuth2ResourceServerAutoConfiguration`
- Auth test keeps security enabled; use `opaqueToken()` from `spring-security-test` to simulate scopes

### Service tests
- No Spring context — instantiate the class under test directly
- Use `spyk()` when you need a real collaborator but want to stub one method on it

### Repository tests
- Always `@DataJpaTest` + `@Import(PostgresContainerConfig::class)`
- Clean up with `deleteAllInBatch()` in `beforeEach` — don't rely on `@Transactional` rollback alone
- Call `entityManager.clear()` after `persistAndFlush()` to force a real DB read on assertions
- Test DB constraints (unique keys, not-null) explicitly — these are the highest-value repository tests

### Parameterized tests
- Read `templates/ParameterizedTest_template.md` before writing tests that repeat the same assertion over multiple inputs
- Use **`listOf(...).forEach { test(...) }`** for simple cases — it's idiomatic, requires no extra dependency, and is easy to read
- Use **Kotest `withData`** when each case needs a distinct named entry in the CI test report (requires `kotest-framework-datatest`)
- Define a local `data class` for the row type when a case has more than two fields — avoids unreadable `Triple`/`Pair` destructuring
- Name each test case so the failure message is self-explanatory without reading the input values

### Fixtures
- Read `templates/Fixtures_template.md` before creating any test data helper
- Pick the right scope: **top-level functions** for data shared across test classes (e.g. `createOrgUnit()`), **companion object** for complex hierarchies (e.g. `OrgUnitTestBuilder`), **inline private helpers** for simple objects used only within one test class
- Always use **default parameter values** so callers only specify what matters for the test
- **JSON fixtures** for client test responses go in `src/test/resources/fixtures/<client-name>/<scenario>.json` — never inline large JSON strings in test code

### Client tests
- Store JSON fixtures in `src/test/resources/fixtures/<client-name>/<scenario>.json`
- Always call `mockServer.verify()` at the end of each test
- Reset with `mockServer.reset()` in `beforeTest`

---

## Running Tests

```bash
./mvnw test                          # all tests
./mvnw test -Dtest=MyServiceTest     # single class
./mvnw test -Dtest="MyService*"      # pattern
make test                            # format + build + test (pre-commit)
```

See `agent_docs/pre_commit.md` for the full pre-commit checklist.