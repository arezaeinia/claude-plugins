# Repository Test Template

Integration test against a real Postgres TestContainer. Always use `@DataJpaTest` + `@Import(PostgresContainerConfig::class)`.

```kotlin
package com.example.project.repository

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.extensions.ApplyExtension
import io.kotest.core.spec.style.FunSpec
import io.kotest.extensions.spring.SpringExtension
import io.kotest.matchers.shouldBe
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager
import org.springframework.context.annotation.Import
import org.springframework.dao.DataIntegrityViolationException
import org.zalando.orgstructure.config.PostgresContainerConfig

@DataJpaTest
@Import(PostgresContainerConfig::class)
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
                entityManager.clear() // force a real DB read on the next query

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
- Wrap cleanup in `runCatching { }` if multiple repositories depend on each other and deletion order matters:

```kotlin
beforeEach {
    runCatching { orderRepository.deleteAllInBatch() }
    runCatching { userRepository.deleteAllInBatch() }
    entityManager.flush()
    entityManager.clear()
}
```
