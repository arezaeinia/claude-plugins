# Repository Test Template

Integration test against a real Postgres TestContainer. Always use `@DataJpaTest` + `@Import(PostgresContainerConfig.class)`.

```java
package com.example.project.repository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.context.annotation.Import;
import org.springframework.dao.DataIntegrityViolationException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
@Import(PostgresContainerConfig.class)
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
            entityManager.clear(); // force a real DB read on the next query

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
