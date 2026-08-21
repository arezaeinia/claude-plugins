# Service Test Template (Kotlin + JUnit 5 + Mockito)

Pure unit test — no Spring context, no DB. Use `@ExtendWith(MockitoExtension::class)` with `@InjectMocks` for the subject and `@Mock` for all dependencies. Use `whenever(...)` from `mockito-kotlin` for stubbing.

```kotlin
package com.example.project.service

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.junit.jupiter.MockitoExtension
import org.mockito.kotlin.any
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

@ExtendWith(MockitoExtension::class)
class UserServiceTest {

    @Mock
    private lateinit var userRepository: UserRepository

    @Mock
    private lateinit var otherService: OtherService

    @InjectMocks
    private lateinit var subject: UserService

    @Nested
    @DisplayName("getUser")
    inner class GetUser {

        @Test
        @DisplayName("returns user when found")
        fun returnsUser() {
            val user = UserEntity(1, "Alex")
            whenever(userRepository.findById(1)).thenReturn(user)

            val result = subject.getUser(1)

            assertThat(result.name).isEqualTo("Alex")
            verify(userRepository).findById(1)
        }

        @Test
        @DisplayName("throws NotFoundException when user does not exist")
        fun throwsWhenNotFound() {
            whenever(userRepository.findById(99)).thenReturn(null)

            assertThatThrownBy { subject.getUser(99) }
                .isInstanceOf(NotFoundException::class.java)
        }
    }

    @Nested
    @DisplayName("createUser")
    inner class CreateUser {

        @Test
        @DisplayName("saves and returns entity")
        fun savesAndReturns() {
            val dto = UserCreateDto("Alex")
            val saved = UserEntity(1, "Alex")
            whenever(userRepository.save(any())).thenReturn(saved)

            val result = subject.createUser(dto)

            assertThat(result.id).isEqualTo(1)
            verify(userRepository).save(any())
        }
    }
}
```

## Notes

**Use `@Spy` when a collaborator needs real logic with one method stubbed:**

```kotlin
@Spy
private lateinit var realCollaborator: RealCollaborator

@BeforeEach
fun setUp() {
    doReturn(cachedResult).whenever(realCollaborator).expensiveMethod()
}
```

**Use `lenient()` stubs for dependencies not the focus of a test** (avoids `UnnecessaryStubbingException`):

```kotlin
lenient().whenever(auditService.log(any())).thenReturn(true)
```
