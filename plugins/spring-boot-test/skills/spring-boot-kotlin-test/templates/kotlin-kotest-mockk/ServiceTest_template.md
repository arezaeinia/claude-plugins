# Service Test Template

Pure unit test — no Spring context, no DB. Instantiate the class under test directly and mock all dependencies with MockK.

```kotlin
package com.example.project.service

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify

class UserServiceTest : FunSpec({

    val userRepository = mockk<UserRepository>()
    val otherService = mockk<OtherService>()
    val subject = UserService(userRepository, otherService)

    beforeTest { clearAllMocks() }

    context("getUser") {
        test("returns user when found") {
            val user = UserEntity(id = 1, name = "Alex")
            every { userRepository.findById(1) } returns user

            val result = subject.getUser(1)

            result.name shouldBe "Alex"
            verify(exactly = 1) { userRepository.findById(1) }
        }

        test("throws NotFoundException when user does not exist") {
            every { userRepository.findById(99) } returns null

            shouldThrow<NotFoundException> {
                subject.getUser(99)
            }
        }
    }

    context("createUser") {
        test("saves and returns entity") {
            val dto = UserCreateDto(name = "Alex")
            val saved = UserEntity(id = 1, name = "Alex")
            every { userRepository.save(any()) } returns saved

            val result = subject.createUser(dto)

            result.id shouldBe 1
            verify(exactly = 1) { userRepository.save(any()) }
        }
    }
})
```

## Notes

**Use `spyk()` when a collaborator needs real logic with one method stubbed:**

```kotlin
val realCollaborator = spyk(RealCollaborator(dep1, dep2))
every { realCollaborator.expensiveMethod() } returns cachedResult
```

**Use `mockk(relaxed = true)` for dependencies that are not the focus of a test** (avoids boilerplate stubs for every call):

```kotlin
val auditService = mockk<AuditService>(relaxed = true)
```
