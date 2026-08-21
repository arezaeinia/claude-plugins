# Repository Test Template (Kotlin + JUnit 5 + Mockito)

Integration test against a real database TestContainer. Default is Postgres. If the project uses a different database, use the same initializer pattern with the appropriate TestContainers image and JDBC driver.

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

    companion object {
        private val POSTGRES = PostgreSQLContainer<Nothing>("postgres:16-alpine").apply {
            withDatabaseName("test")
            withUsername("test")
            withPassword("test")
            withReuse(true)
        }

        init {
            POSTGRES.start()
        }
    }

    override fun initialize(context: ConfigurableApplicationContext) {
        TestPropertySourceUtils.addInlinedPropertiesToEnvironment(
            context,
            "spring.datasource.url=${POSTGRES.jdbcUrl}",
            "spring.datasource.username=${POSTGRES.username}",
            "spring.datasource.password=${POSTGRES.password}",
            "spring.datasource.driver-class-name=org.postgresql.Driver"
        )
    }
}
```

### Other databases

For any other database, apply the same pattern using the matching TestContainers image and JDBC driver:

```kotlin
package com.example.project.config

import org.springframework.context.ApplicationContextInitializer
import org.springframework.context.ConfigurableApplicationContext
import org.springframework.test.context.support.TestPropertySourceUtils
import org.testcontainers.containers.JdbcDatabaseContainer

class DatabaseContainerInitializer : ApplicationContextInitializer<ConfigurableApplicationContext> {

    companion object {
        // Replace with the appropriate TestContainers container class and image
        private val DB: JdbcDatabaseContainer<*> = /* ContainerClass */("<image>").apply {
            withDatabaseName("test")
            withUsername("test")
            withPassword("test")
            withReuse(true)
        }

        init { DB.start() }
    }

    override fun initialize(context: ConfigurableApplicationContext) {
        TestPropertySourceUtils.addInlinedPropertiesToEnvironment(
            context,
            "spring.datasource.url=${DB.jdbcUrl}",
            "spring.datasource.username=${DB.username}",
            "spring.datasource.password=${DB.password}",
            "spring.datasource.driver-class-name=<driver-class>"
        )
    }
}
```

Then register the initializer in `src/test/resources/META-INF/spring.factories`:

```properties
org.springframework.context.ApplicationContextInitializer=\
  com.example.project.config.PostgresContainerInitializer
```

---

## Test class

Use `@DataJpaTest` + `@ContextConfiguration` pointing to the initializer. No `@ExtendWith(SpringExtension::class)` needed — `@DataJpaTest` includes it.

```kotlin
package com.example.project.repository

import com.example.project.config.PostgresContainerInitializer
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.test.context.ContextConfiguration

@DataJpaTest
@AutoConfigureTestDatabase(replace = Replace.NONE)
@ContextConfiguration(initializers = [PostgresContainerInitializer::class])
class UserRepositoryTest {

    @Autowired
    private lateinit var repository: UserRepository

    @Autowired
    private lateinit var entityManager: TestEntityManager

    @BeforeEach
    fun setUp() {
        repository.deleteAllInBatch()
        entityManager.flush()
        entityManager.clear()
    }

    @Nested
    @DisplayName("findByEmail")
    inner class FindByEmail {

        @Test
        @DisplayName("returns entity when it exists")
        fun returnsEntity() {
            val saved = entityManager.persistAndFlush(
                UserEntity("alice@example.com", "Alice")
            )
            entityManager.clear()

            val result = repository.findByEmail("alice@example.com")

            assertThat(result).isEqualTo(saved)
        }

        @Test
        @DisplayName("returns null when email does not exist")
        fun returnsNull() {
            assertThat(repository.findByEmail("missing@example.com")).isNull()
        }
    }

    @Nested
    @DisplayName("constraints")
    inner class Constraints {

        @Test
        @DisplayName("throws on duplicate email")
        fun throwsOnDuplicate() {
            entityManager.persistAndFlush(UserEntity("dup@example.com", "First"))
            entityManager.clear()

            assertThatThrownBy {
                entityManager.persistAndFlush(UserEntity("dup@example.com", "Second"))
            }.isInstanceOf(DataIntegrityViolationException::class.java)
        }
    }
}
```

## Notes

- Clean up in `@BeforeEach` with `deleteAllInBatch()` — do not rely on `@Transactional` rollback alone
- Always call `entityManager.clear()` after `persistAndFlush()` to force a real DB read on assertions
- Test DB constraints (unique keys, not-null) explicitly — these are the highest-value repository tests
- `withReuse(true)` on the container keeps it alive across test runs — speeds up local development
- When multiple repositories depend on each other, wrap each deletion to handle ordering:

```kotlin
@BeforeEach
fun setUp() {
    runCatching { orderRepository.deleteAllInBatch() }
    runCatching { userRepository.deleteAllInBatch() }
    entityManager.flush()
    entityManager.clear()
}
```
