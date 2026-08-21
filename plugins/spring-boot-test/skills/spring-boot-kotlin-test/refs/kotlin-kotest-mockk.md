# Conventions: Kotlin + Kotest + MockK

## Templates

| Test type                     | Template file                                | When to use                                                                      |
|-------------------------------|----------------------------------------------|----------------------------------------------------------------------------------|
| Controller (behaviour + auth) | `../templates/kotlin-kotest-mockk/ControllerTest_template.md`    | REST endpoints; two classes: one for behaviour, one for auth                     |
| Service                       | `../templates/kotlin-kotest-mockk/ServiceTest_template.md`       | Pure unit tests for service classes                                              |
| Repository                    | `../templates/kotlin-kotest-mockk/RepositoryTest_template.md`    | Integration tests against real Postgres via TestContainer                        |
| Client                        | `../templates/kotlin-kotest-mockk/ClientTest_template.md`        | Outbound HTTP clients using WireMock (`@WireMockTest`)                           |
| Fixtures                      | `../templates/kotlin-kotest-mockk/Fixtures_template.md`          | Test data helpers — read before creating any fixture, builder, or JSON file      |
| Parameterized tests           | `../templates/kotlin-kotest-mockk/ParameterizedTest_template.md` | Multiple inputs against the same logic — `forEach` loop or Kotest `withData`     |

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
- Default to Postgres. If the project uses a different database, check `pom.xml` or `build.gradle` for the JDBC dependency and use the matching TestContainers image and driver
- If no container initializer exists in the project, create one — see `../templates/kotlin-kotest-mockk/RepositoryTest_template.md` for the Postgres template and the generic pattern for other databases
- Use `@DataJpaTest` + `@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)` + `@ContextConfiguration(initializers = [XxxContainerInitializer::class])` — `Replace.NONE` prevents Spring from silently swapping the datasource with H2
- Clean up with `deleteAllInBatch()` in `beforeEach` — don't rely on `@Transactional` rollback alone
- Call `entityManager.clear()` after `persistAndFlush()` to force a real DB read on assertions
- Test DB constraints (unique keys, not-null) explicitly — these are the highest-value repository tests

### Parameterized tests
- Read `../templates/kotlin-kotest-mockk/ParameterizedTest_template.md` before writing tests that repeat the same assertion over multiple inputs
- Use **`listOf(...).forEach { test(...) }`** for simple cases — idiomatic, no extra dependency, easy to read
- Use **Kotest `withData`** when each case needs a distinct named entry in the CI test report (requires `kotest-framework-datatest`)
- Define a local `data class` for the row type when a case has more than two fields — avoids unreadable `Triple`/`Pair` destructuring
- Name each test case so the failure message is self-explanatory without reading the input values

### Fixtures
- Read `../templates/kotlin-kotest-mockk/Fixtures_template.md` before creating any test data helper
- Pick the right scope: **top-level functions** for data shared across test classes, **companion object** for complex hierarchies, **inline private helpers** for simple objects used only within one test class
- Always use **default parameter values** so callers only specify what matters for the test
- **JSON fixtures** for client test responses go in `src/test/resources/fixtures/clients/<client-name>/<scenario>.json` — never inline large JSON strings in test code

### Client tests
- Store JSON fixtures in `src/test/resources/fixtures/clients/<client-name>/<scenario>.json`
- Use `verify(getRequestedFor(...))` to assert the request was made
- Stubs reset automatically between tests — no manual reset needed with `@WireMockTest`
- **POST/PUT/PATCH**: load the full request body from a fixture file and use `withRequestBody(equalToJson(requestJson))` on both stub and verify
- **GET**: no request body — omit `withRequestBody` entirely
