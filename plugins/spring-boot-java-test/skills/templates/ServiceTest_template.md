# Service Test Template

Pure unit test — no Spring context, no DB. Use `@ExtendWith(MockitoExtension.class)` with `@InjectMocks` for the subject and `@Mock` for all dependencies.

```java
package com.example.project.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private OtherService otherService;

    @InjectMocks
    private UserService subject;

    @Nested
    @DisplayName("getUser")
    class GetUser {

        @Test
        @DisplayName("returns user when found")
        void returnsUser() {
            var user = new UserEntity(1, "Alex");
            when(userRepository.findById(1)).thenReturn(user);

            var result = subject.getUser(1);

            assertThat(result.getName()).isEqualTo("Alex");
            verify(userRepository).findById(1);
        }

        @Test
        @DisplayName("throws NotFoundException when user does not exist")
        void throwsWhenNotFound() {
            when(userRepository.findById(99)).thenReturn(null);

            assertThatThrownBy(() -> subject.getUser(99))
                .isInstanceOf(NotFoundException.class);
        }
    }

    @Nested
    @DisplayName("createUser")
    class CreateUser {

        @Test
        @DisplayName("saves and returns entity")
        void savesAndReturns() {
            var dto = new UserCreateDto("Alex");
            var saved = new UserEntity(1, "Alex");
            when(userRepository.save(any())).thenReturn(saved);

            var result = subject.createUser(dto);

            assertThat(result.getId()).isEqualTo(1);
            verify(userRepository).save(any());
        }
    }
}
```

## Notes

**Use `@Spy` when a collaborator needs real logic with one method stubbed:**

```java
@Spy
private RealCollaborator realCollaborator;

@BeforeEach
void setUp() {
    doReturn(cachedResult).when(realCollaborator).expensiveMethod();
}
```

**Use `lenient()` stubs for dependencies not the focus of a test** (avoids `UnnecessaryStubbingException`):

```java
lenient().when(auditService.log(any())).thenReturn(true);
```
