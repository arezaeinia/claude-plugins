# Conventions: Kotlin + JUnit 5 + Mockito

Used when a Kotlin project's build file declares `junit-jupiter` and `mockito` (or `mockito-kotlin`) as test dependencies instead of Kotest and MockK.

## Templates

| Test type                     | Template file                                                       | When to use                                                                  |
|-------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------------|
| Controller (behaviour + auth) | `../templates/kotlin-junit5-mockito/ControllerTest_template.md`    | REST endpoints; two classes: one for behaviour, one for auth                 |
| Service                       | `../templates/kotlin-junit5-mockito/ServiceTest_template.md`       | Pure unit tests for service classes                                          |
| Repository                    | `../templates/kotlin-junit5-mockito/RepositoryTest_template.md`    | Integration tests against real Postgres via TestContainer                    |
| Client                        | `../templates/kotlin-junit5-mockito/ClientTest_template.md`        | Outbound HTTP clients using WireMock (`@WireMockTest`)                       |
| Fixtures                      | `../templates/kotlin-junit5-mockito/Fixtures_template.md`          | Test data helpers — read before creating any fixture or builder              |
| Parameterized tests           | `../templates/kotlin-junit5-mockito/ParameterizedTest_template.md` | Multiple inputs — `@ParameterizedTest` with `@MethodSource` or `@CsvSource` |

## Key Conventions

### JUnit 5 structure in Kotlin
- Use `@Nested` inner classes with `@DisplayName("when ...")` to group related cases
- Use `@DisplayName("should ...")` on individual `@Test` methods
- Use `@BeforeEach` to reset mocks and shared state between tests
- Prefer AssertJ: `assertThat(result).isEqualTo(...)`, `assertThatThrownBy { ... }.isInstanceOf(...)`, `assertThat(list).hasSize(...)`

### Controller tests
- Two separate classes per controller: `XxxControllerTest` (behaviour) and `XxxControllerAuthTest` (security)
- Use `@MockitoBean` (Spring Boot 3.4+) for mocking service dependencies in `@WebMvcTest` slices
- Behaviour test excludes `SecurityAutoConfiguration` and `OAuth2ResourceServerAutoConfiguration`
- Auth test keeps security enabled; use `opaqueToken()` from `spring-security-test` to simulate scopes

### Service tests
- No Spring context — use `@ExtendWith(MockitoExtension::class)` on the test class
- Declare mock dependencies with `@Mock lateinit var dep: DepClass`
- Declare the subject with `@InjectMocks lateinit var subject: ServiceClass`
- Stub with `whenever(dep.method()).thenReturn(value)` (from `mockito-kotlin`)
- Verify calls with `verify(dep).method()`
- Use `@Spy` when you need real logic on a collaborator with one method stubbed; use `doReturn(...).whenever(spy).method()` to avoid calling real code during stubbing

### Repository tests
- Default to Postgres. If the project uses a different database, check `pom.xml` or `build.gradle` for the JDBC dependency and use the matching TestContainers image and driver
- If no container initializer exists in the project, create one — see `../templates/kotlin-junit5-mockito/RepositoryTest_template.md`
- Use `@DataJpaTest` + `@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)` + `@ContextConfiguration(initializers = [XxxContainerInitializer::class])` — `Replace.NONE` prevents Spring from silently swapping the datasource with H2
- Clean up with `deleteAllInBatch()` in `@BeforeEach` — don't rely on `@Transactional` rollback alone
- Call `entityManager.clear()` after `persistAndFlush()` to force a real DB read on assertions
- Test DB constraints (unique keys, not-null) explicitly — these are the highest-value repository tests

### Parameterized tests
- Read `../templates/kotlin-junit5-mockito/ParameterizedTest_template.md` before writing tests that repeat the same assertion over multiple inputs
- Use `@ParameterizedTest` + `@MethodSource` for cases with multiple fields — define a `@JvmStatic` method in a `companion object` returning `Stream<Arguments>`
- Use `@ParameterizedTest` + `@CsvSource` for simple two-field cases where inline values are readable
- Use a local `data class` for the row type when a case has more than two fields

### Fixtures
- Read `../templates/kotlin-junit5-mockito/Fixtures_template.md` before creating any test data helper
- Pick the right scope: **top-level functions** for data shared across test classes, **companion object** for complex hierarchies, **inline private helpers** for simple objects used only within one test class
- Always use **default parameter values** so callers only specify what matters for the test
- **JSON fixtures** for client test responses go in `src/test/resources/fixtures/clients/<client-name>/<scenario>.json` — never inline large JSON strings in test code

### Client tests
- Store JSON fixtures in `src/test/resources/fixtures/clients/<client-name>/<scenario>.json`
- Use `verify(getRequestedFor(...))` to assert the request was made
- Stubs reset automatically between tests — no manual reset needed with `@WireMockTest`
- **POST/PUT/PATCH**: load the full request body from a fixture file and use `withRequestBody(equalToJson(requestJson))` on both stub and verify
- **GET**: no request body — omit `withRequestBody` entirely

## Required Dependencies

Add to `pom.xml` if not already present:

```xml
<!-- mockito-kotlin provides Kotlin-friendly DSL: whenever(), doReturn(), etc. -->
<dependency>
  <groupId>org.mockito.kotlin</groupId>
  <artifactId>mockito-kotlin</artifactId>
  <scope>test</scope>
</dependency>
```

Or in `build.gradle.kts`:
```kotlin
testImplementation("org.mockito.kotlin:mockito-kotlin:5.x.x")
```
