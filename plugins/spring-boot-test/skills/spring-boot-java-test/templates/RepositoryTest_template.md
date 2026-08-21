# Repository Test Template

Integration test against a real database TestContainer. Default is Postgres. If the project uses a different database, use the same initializer pattern with the appropriate TestContainers image and JDBC driver.

## Setup: Container Initializer

If the project does not already have a container initializer, create one in `src/test/java/com/example/project/config/`:

### Postgres (default)

```java
package com.example.project.config;

import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.test.context.support.TestPropertySourceUtils;
import org.testcontainers.containers.PostgreSQLContainer;

public class PostgresContainerInitializer implements ApplicationContextInitializer<ConfigurableApplicationContext> {

    private static final PostgreSQLContainer<?> POSTGRES =
        new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("test")
            .withUsername("test")
            .withPassword("test")
            .withReuse(true);

    static {
        POSTGRES.start();
    }

    @Override
    public void initialize(ConfigurableApplicationContext context) {
        TestPropertySourceUtils.addInlinedPropertiesToEnvironment(
            context,
            "spring.datasource.url=" + POSTGRES.getJdbcUrl(),
            "spring.datasource.username=" + POSTGRES.getUsername(),
            "spring.datasource.password=" + POSTGRES.getPassword(),
            "spring.datasource.driver-class-name=org.postgresql.Driver"
        );
    }
}
```

### Other databases

For any other database, apply the same pattern using the matching TestContainers image and JDBC driver. Replace the container type, image tag, and driver class name accordingly:

```java
package com.example.project.config;

import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.test.context.support.TestPropertySourceUtils;
import org.testcontainers.containers.JdbcDatabaseContainer;

public class DatabaseContainerInitializer implements ApplicationContextInitializer<ConfigurableApplicationContext> {

    // Replace with the appropriate TestContainers container class and image
    private static final JdbcDatabaseContainer<?> DB =
        new <ContainerClass>("<image>")
            .withDatabaseName("test")
            .withUsername("test")
            .withPassword("test")
            .withReuse(true);

    static {
        DB.start();
    }

    @Override
    public void initialize(ConfigurableApplicationContext context) {
        TestPropertySourceUtils.addInlinedPropertiesToEnvironment(
            context,
            "spring.datasource.url=" + DB.getJdbcUrl(),
            "spring.datasource.username=" + DB.getUsername(),
            "spring.datasource.password=" + DB.getPassword(),
            "spring.datasource.driver-class-name=<driver-class>"
        );
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

Use `@DataJpaTest` + `@ContextConfiguration` pointing to the initializer.

```java
package com.example.project.repository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ContextConfiguration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ContextConfiguration(initializers = PostgresContainerInitializer.class)
class UserRepositoryTest {

    @Autowired
    private UserRepository repository;

    @Autowired
    private TestEntityManager entityManager;

    @BeforeEach
    void setUp() {
        repository.deleteAllInBatch();
        entityManager.flush();
        entityManager.clear();
    }

    @Nested
    @DisplayName("findByEmail")
    class FindByEmail {

        @Test
        @DisplayName("returns entity when it exists")
        void returnsEntity() {
            var saved = entityManager.persistAndFlush(
                new UserEntity("alice@example.com", "Alice")
            );
            entityManager.clear();

            var result = repository.findByEmail("alice@example.com");

            assertThat(result).isEqualTo(saved);
        }

        @Test
        @DisplayName("returns null when email does not exist")
        void returnsNull() {
            assertThat(repository.findByEmail("missing@example.com")).isNull();
        }
    }

    @Nested
    @DisplayName("constraints")
    class Constraints {

        @Test
        @DisplayName("throws on duplicate email")
        void throwsOnDuplicate() {
            entityManager.persistAndFlush(new UserEntity("dup@example.com", "First"));
            entityManager.clear();

            assertThatThrownBy(() ->
                entityManager.persistAndFlush(new UserEntity("dup@example.com", "Second"))
            ).isInstanceOf(DataIntegrityViolationException.class);
        }
    }
}
```

## Notes

- Clean up in `@BeforeEach` with `deleteAllInBatch()` — do not rely on `@Transactional` rollback alone
- Always call `entityManager.clear()` after `persistAndFlush()` to force a real DB read on assertions
- Test DB constraints (unique keys, not-null) explicitly — these are the highest-value repository tests
- `withReuse(true)` on the container keeps it alive across test runs — speeds up local development
- When multiple repositories depend on each other, wrap each deletion to handle order:

```java
@BeforeEach
void setUp() {
    try { orderRepository.deleteAllInBatch(); } catch (Exception ignored) {}
    try { userRepository.deleteAllInBatch(); } catch (Exception ignored) {}
    entityManager.flush();
    entityManager.clear();
}
```
