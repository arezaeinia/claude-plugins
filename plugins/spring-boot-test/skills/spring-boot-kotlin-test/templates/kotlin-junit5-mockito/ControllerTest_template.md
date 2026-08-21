# Controller Test Templates (Kotlin + JUnit 5 + Mockito)

Each controller gets two separate test classes: one for behaviour, one for auth.

---

## File 1: Behaviour Test

Excludes security — focuses purely on request/response mapping. Use `@MockitoBean` for all service dependencies.

```kotlin
package com.example.project.controller

import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.autoconfigure.security.oauth2.resource.servlet.OAuth2ResourceServerAutoConfiguration
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.test.context.bean.override.mockito.MockitoBean
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get

@WebMvcTest(
    controllers = [UserController::class],
    excludeAutoConfiguration = [
        SecurityAutoConfiguration::class,
        OAuth2ResourceServerAutoConfiguration::class
    ]
)
class UserControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockitoBean
    private lateinit var userService: UserService

    @Nested
    @DisplayName("GET /api/users/{id}")
    inner class GetUser {

        @Test
        @DisplayName("should return HTTP 200 with user data")
        fun returnsUser() {
            val userId = "user-123"
            whenever(userService.getUserById(userId)).thenReturn(UserResponse(userId, "Alex"))

            mockMvc.get("/api/users/{id}", userId) {
                accept(MediaType.APPLICATION_JSON)
            }.andExpect {
                status { isOk() }
                jsonPath("$.id") { value(userId) }
                jsonPath("$.name") { value("Alex") }
            }

            verify(userService).getUserById(userId)
        }

        @Test
        @DisplayName("should return HTTP 404 when user not found")
        fun returnsNotFound() {
            whenever(userService.getUserById("missing")).thenThrow(NotFoundException("not found"))

            mockMvc.get("/api/users/{id}", "missing") {
                accept(MediaType.APPLICATION_JSON)
            }.andExpect {
                status { isNotFound() }
            }
        }
    }
}
```

---

## File 2: Auth Test

Keeps security **enabled** — tests that the right scopes are enforced. Do **not** exclude `SecurityAutoConfiguration` or `OAuth2ResourceServerAutoConfiguration` here.

```kotlin
package com.example.project.controller

import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.whenever
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.security.oauth2.server.resource.introspection.OpaqueTokenIntrospector
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.opaqueToken
import org.springframework.test.context.bean.override.mockito.MockitoBean
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get

@WebMvcTest(controllers = [UserController::class])
class UserControllerAuthTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockitoBean
    private lateinit var userService: UserService

    // Mock all beans the security config depends on
    @MockitoBean
    private lateinit var tokenIntrospector: OpaqueTokenIntrospector

    @Nested
    @DisplayName("GET /api/users/{id}")
    inner class GetUser {

        @Test
        @DisplayName("should return HTTP 401 when no token provided")
        fun returnsUnauthorized() {
            mockMvc.get("/api/users/123")
                .andExpect { status { isUnauthorized() } }
        }

        @Test
        @DisplayName("should return HTTP 403 when token lacks required scope")
        fun returnsForbidden() {
            mockMvc.get("/api/users/123") {
                with(opaqueToken().attributes { it["scope"] = "some.other.scope" })
            }.andExpect { status { isForbidden() } }
        }

        @Test
        @DisplayName("should return HTTP 200 when token has required scope")
        fun returnsOk() {
            whenever(userService.getUserById("123")).thenReturn(UserResponse("123", "Alex"))

            mockMvc.get("/api/users/123") {
                with(opaqueToken().attributes { it["scope"] = "required.scope" })
            }.andExpect { status { isOk() } }
        }
    }
}
```
