# Controller Test Templates

Each controller gets two separate test classes: one for behaviour, one for auth.

---

## File 1: Behaviour Test

Excludes security — focuses purely on request/response mapping. Use `@MockkBean` for all service dependencies.

```kotlin
package com.example.project.controller

import com.ninjasquad.springmockk.MockkBean
import io.kotest.core.spec.style.FunSpec
import io.kotest.extensions.spring.SpringExtension
import io.mockk.every
import io.mockk.verify
import org.springframework.boot.autoconfigure.security.oauth2.resource.servlet.OAuth2ResourceServerAutoConfiguration
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*

@WebMvcTest(
    controllers = [UserController::class],
    excludeAutoConfiguration = [
        SecurityAutoConfiguration::class,
        OAuth2ResourceServerAutoConfiguration::class,
    ],
)
class UserControllerTest(private val mockMvc: MockMvc) : FunSpec() {

    override fun extensions() = listOf(SpringExtension)

    @MockkBean
    private lateinit var userService: UserService

    init {
        test("GET /api/users/{id} should return HTTP 200 with user data") {
            val userId = "user-123"
            every { userService.getUserById(userId) } returns UserResponse(id = userId, name = "Alex")

            mockMvc.perform(get("/api/users/$userId").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.id").value(userId))
                .andExpect(jsonPath("$.name").value("Alex"))

            verify(exactly = 1) { userService.getUserById(userId) }
        }

        test("GET /api/users/{id} should return HTTP 404 when user not found") {
            every { userService.getUserById("missing") } throws NotFoundException("not found")

            mockMvc.perform(get("/api/users/missing").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound)
        }
    }
}
```

---

## File 2: Auth Test

Keeps security **enabled** — tests that the right scopes are enforced. Do **not** exclude `SecurityAutoConfiguration` or `OAuth2ResourceServerAutoConfiguration` here.

```kotlin
package com.example.project.controller

import com.ninjasquad.springmockk.MockkBean
import io.kotest.core.spec.style.FunSpec
import io.kotest.extensions.spring.SpringExtension
import io.mockk.every
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.security.oauth2.server.resource.introspection.OpaqueTokenIntrospector
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.opaqueToken
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status

@WebMvcTest(controllers = [UserController::class])
class UserControllerAuthTest(private val mockMvc: MockMvc) : FunSpec() {

    override fun extensions() = listOf(SpringExtension)

    @MockkBean
    private lateinit var userService: UserService

    // Mock all beans the security config depends on
    @MockkBean
    private lateinit var tokenIntrospector: OpaqueTokenIntrospector

    init {
        test("GET /api/users/{id} should return HTTP 401 when no token provided") {
            mockMvc.perform(get("/api/users/123"))
                .andExpect(status().isUnauthorized)
        }

        test("GET /api/users/{id} should return HTTP 403 when token lacks required scope") {
            mockMvc.perform(
                get("/api/users/123")
                    .with(opaqueToken().attributes { it["scope"] = "some.other.scope" })
            ).andExpect(status().isForbidden)
        }

        test("GET /api/users/{id} should return HTTP 200 when token has required scope") {
            every { userService.getUserById("123") } returns UserResponse(id = "123", name = "Alex")

            mockMvc.perform(
                get("/api/users/123")
                    .with(opaqueToken().attributes { it["scope"] = "required.scope" })
            ).andExpect(status().isOk)
        }
    }
}
```
