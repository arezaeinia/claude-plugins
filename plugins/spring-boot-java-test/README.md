# spring-boot-java-test

A Claude Code skill that shapes the test architecture, framework conventions, and maintainability patterns for Java/Spring Boot services — not just generates test code.

It applies the [Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) end-to-end: picking the right test type for each class, enforcing consistent structure across the codebase, and establishing conventions (naming, fixture scope, mock boundaries) that keep the test suite easy to maintain as it grows.

**Stack:** Java 21 · Spring Boot 3.4+ · JUnit 5 · Mockito · AssertJ · TestContainers

## What it generates

| Class type | Test type | Framework |
|---|---|---|
| REST controller | `@WebMvcTest` slice (behaviour + auth) | JUnit 5 · `@MockitoBean` · Spring Security Test |
| Service | Pure unit test, no Spring context | JUnit 5 · Mockito · AssertJ |
| JPA repository | Integration test against real Postgres | JUnit 5 · TestContainers · `@DataJpaTest` |
| Outbound HTTP client | `MockRestServiceServer` | JUnit 5 · Mockito · Spring Test |
| Any | Parameterized test | `@ParameterizedTest` · `@MethodSource` / `@CsvSource` |

## Usage

Just ask Claude naturally — it triggers automatically:

```
Write a test for UserService.createUser()
Add tests for OrderRepository
What kind of test should I write for this controller?
```

## Installation

```bash
/plugin install spring-boot-java-test@arezaeinia-claude-plugins
```

If you haven't added this marketplace yet:

```bash
/plugin marketplace add arezaeinia/claude-plugins
```
