# Claude Plugins

A marketplace of Claude Code plugins focused on test architecture and code quality for Spring Boot services.

## Plugins

### `spring-boot-kotlin-test`

Shapes the test architecture, framework conventions, and maintainability patterns for Kotlin/Spring Boot services — not just generates test code. Applies the [Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) end-to-end: the right test type for each class, consistent structure across the codebase, and conventions that keep the suite easy to maintain as it grows.

**Covers:**
- Controller tests (`@WebMvcTest`) — behaviour and auth as separate classes
- Service unit tests — no Spring context, pure MockK
- Repository integration tests — real Postgres via TestContainers
- Outbound HTTP client tests — `MockRestServiceServer`
- Parameterized tests — `forEach` loop or Kotest `withData`
- Test fixtures and data builders

**Stack:** Kotest `FunSpec` · MockK · TestContainers · Spring Security Test

---

### `spring-boot-java-test`

Shapes the test architecture, framework conventions, and maintainability patterns for Java/Spring Boot services. Applies the [Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) end-to-end: the right test type for each class, consistent structure across the codebase, and conventions that keep the suite easy to maintain as it grows.

**Covers:**
- Controller tests (`@WebMvcTest`) — behaviour and auth as separate classes
- Service unit tests — no Spring context, pure Mockito
- Repository integration tests — real Postgres via TestContainers
- Outbound HTTP client tests — `MockRestServiceServer`
- Parameterized tests — `@ParameterizedTest` with `@MethodSource` / `@CsvSource`
- Test fixtures and data builders

**Stack:** Java 21 · JUnit 5 · Mockito · AssertJ · TestContainers · Spring Boot 3.4+

---

## Installation

### Option 1 — Add as a marketplace (recommended)

This lets Claude Code discover and install plugins from this repo via `/plugin discover`.

Run this once in your terminal:

```bash
/plugin marketplace add arezaeinia/claude-plugins
```

Then install the plugin:

```bash
/plugin install spring-boot-kotlin-test@arezaeinia-claude-plugins
```

### Option 2 — Manual install

Clone this repo and copy the plugin into your project's `.claude` directory:

```bash
git clone https://github.com/arezaeinia/claude-plugins.git
cp -r claude-plugins/plugins/spring-boot-kotlin-test .claude/plugins/
```

---

## Usage

Once installed, Claude triggers the skill automatically when you:

- Ask it to write a test: `"write a test for UserService"`
- Paste a class and ask for coverage: `"add tests for this"`
- Ask what to test: `"what should I test here?"`
- Write new production code — Claude will proactively suggest tests

You can also invoke it explicitly:

```
/spring-boot-kotlin-test write a controller test for OrderController
```

### Example prompts

```
Write a test for UserService.createUser()
Add repository tests for OrderRepository
What kind of test should I write for this HTTP client?
Generate fixtures for the Order entity
```

---

## Repo structure

```
plugins/
└── spring-boot-kotlin-test/
    ├── .claude-plugin/
    │   └── plugin.json          # plugin metadata
    └── skills/
        ├── SKILL.md             # skill instructions and conventions
        └── templates/
            ├── ControllerTest_template.md
            ├── ServiceTest_template.md
            ├── RepositoryTest_template.md
            ├── ClientTest_template.md
            ├── Fixtures_template.md
            └── ParameterizedTest_template.md
```

---

## Contributing

To add a new plugin:

1. Create a directory under `plugins/<your-plugin-name>/`
2. Add `.claude-plugin/plugin.json` with `name`, `version`, `description`, and `author`
3. Add a `skills/SKILL.md` (and any supporting files)
4. Add a `README.md` for the plugin
5. Open a PR

See `plugins/spring-boot-kotlin-test` as a reference.

---

## License

MIT
