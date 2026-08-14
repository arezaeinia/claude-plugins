# Repository Test Template

Integration test against a real database TestContainer. Default is Postgres — switch to MySQL if the project uses it (check `pom.xml` or `build.gradle` for `mysql-connector-j` or `com.mysql` dependency).

## Setup: Container Initializer

If the project does not already have a container initializer, create one in `src/test/kotlin/com/example/project/config/`:

### Postgres (default)

```kotlin
package com.example.project.config

import org.springframework.context.ApplicationContextInitializer
import org.springframework.context.ConfigurableApplicationContext
import org.springframework.test.context.support.TestPropertySourceUtils
import org.testcontainers.containers.PostgreSQLContainer

class PostgresContainerInitializer : ApplicationContextInitializer<ConfigurableApplicationContext> {
    override fun initialize(context: ConfigurableApplicationContext) {
        TestPropertySourceUtils.addInlinedPropertiesToEnvironment(
            context,
            "spring.datasource.url=${POSTGRES.jdbcUrl}",
            "spring.datasource.username=${POSTGRES.username}",
            "spring.datasource.password=${POSTGRES.password}",
            "spring.datasource.driver-class-name=org.postgresql.Driver",
        )
    }

    companion object {
        private val POSTGRES: PostgreSQLContainer<Nothing> =
            PostgreSQLContainer<Nothing>("postgres:16-alpine").apply {
                withDatabaseName("test")
                withUsername("test")
                withPassword("test")
                withReuse(true)
                start()
            }
    }
}
```

### MySQL (if project uses MySQL)

```kotlin
package com.example.project.config

import org.springframework.context.ApplicationContextInitializer
import org.springframework.context.ConfigurableApplicationContext
import org.springframework.test.context.support.TestPropertySourceUtils
import org.testcontainers.containers.MySQLContainer

class MySQLContainerInitializer : ApplicationContextInitializer<ConfigurableApplicationContext> {
    override fun initialize(context: ConfigurableApplicationContext) {
        TestPropertySourceUtils.addInlinedPropertiesToEnvironment(
            context,
            "spring.datasource.url=${MYSQL.jdbcUrl}",
            "spring.datasource.username=${MYSQL.username}",
            "spring.datasource.password=${MYSQL.password}",
            "spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver",
        )
    }

    companion object {
        private val MYSQL: MySQLContainer<Nothing> =
            MySQLContainer<Nothing>("mysql:8").apply {
                withDatabaseName("test")
                withUsername("test")
                withPassword("test")
                withReuse(true)
                start()
            }
    }
}
```

Then register it in `src/test/resources/META-INF/spring.factories`:

```properties
# Postgres
org.springframework.context.ApplicationContextInitializer=\
  com.example.project.config.PostgresContainerInitializer

# MySQL (use this instead if project uses MySQL)
org.springframework.context.ApplicationContextInitializer=\
  com.example.project.config.MySQLContainerInitializer
```

---

## Test class

Use `@DataJpaTest` + `@ContextConfiguration` pointing to the initializer.

```kotlin
package com.example.project.repository

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.extensions.ApplyExtension
import io.kotest.core.spec.style.FunSpec
import io.kotest.extensions.spring.SpringExtension
import io.kotest.matchers.shouldBe
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.test.context.ContextConfiguration

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ContextConfiguration(initializers = [PostgresContainerInitializer::class])
@ApplyExtension(SpringExtension::class)
class UserRepositoryTest : FunSpec() {

    @Autowired lateinit var repository: UserRepository
    @Autowired lateinit var entityManager: TestEntityManager

    init {
        beforeEach {
            repository.deleteAllInBatch()
            entityManager.flush()
            entityManager.clear()
        }

        context("findByEmail") {
            test("returns entity when it exists") {
                val saved = entityManager.persistAndFlush(
                    UserEntity(email = "alice@example.com", name = "Alice")
                )
                entityManager.clear()

                val result = repository.findByEmail("alice@example.com")

                result shouldBe saved
            }

            test("returns null when email does not exist") {
                repository.findByEmail("missing@example.com") shouldBe null
            }
        }

        context("constraints") {
            test("throws on duplicate email") {
                entityManager.persistAndFlush(UserEntity(email = "dup@example.com", name = "First"))
                entityManager.clear()

                shouldThrow<DataIntegrityViolationException> {
                    entityManager.persistAndFlush(UserEntity(email = "dup@example.com", name = "Second"))
                }
            }
        }
    }
}
```

## Notes

- Clean up in `beforeEach` with `deleteAllInBatch()` — do not rely on `@Transactional` rollback alone
- Always call `entityManager.clear()` after `persistAndFlush()` to force a real DB read on assertions
- Test DB constraints (unique keys, not-null) explicitly — these are the highest-value repository tests
- `withReuse(true)` on the container keeps it alive across test runs — speeds up local development
- Wrap cleanup in `runCatching { }` if multiple repositories depend on each other and deletion order matters:

```kotlin
beforeEach {
    runCatching { orderRepository.deleteAllInBatch() }
    runCatching { userRepository.deleteAllInBatch() }
    entityManager.flush()
    entityManager.clear()
}
```
