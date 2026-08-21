# Controller Test Templates

Each controller gets two separate test classes: one for behaviour, one for auth.

---

## File 1: Behaviour Test

Excludes security — focuses purely on request/response mapping. Use `@MockitoBean` for all service dependencies.

```java
package com.example.project.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.oauth2.resource.servlet.OAuth2ResourceServerAutoConfiguration;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
    controllers = UserController.class,
    excludeAutoConfiguration = {
        SecurityAutoConfiguration.class,
        OAuth2ResourceServerAutoConfiguration.class
    }
)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @Nested
    @DisplayName("GET /api/users/{id}")
    class GetUser {

        @Test
        @DisplayName("should return HTTP 200 with user data")
        void returnsUser() throws Exception {
            var userId = "user-123";
            when(userService.getUserById(userId)).thenReturn(new UserResponse(userId, "Alex"));

            mockMvc.perform(get("/api/users/{id}", userId).accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(userId))
                .andExpect(jsonPath("$.name").value("Alex"));

            verify(userService).getUserById(userId);
        }

        @Test
        @DisplayName("should return HTTP 404 when user not found")
        void returnsNotFound() throws Exception {
            when(userService.getUserById("missing")).thenThrow(new NotFoundException("not found"));

            mockMvc.perform(get("/api/users/{id}", "missing").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
        }
    }
}
```

---

## File 2: Auth Test

Keeps security **enabled** — tests that the right scopes are enforced. Do **not** exclude `SecurityAutoConfiguration` or `OAuth2ResourceServerAutoConfiguration` here.

```java
package com.example.project.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.security.oauth2.server.resource.introspection.OpaqueTokenIntrospector;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.opaqueToken;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = UserController.class)
class UserControllerAuthTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    // Mock all beans the security config depends on
    @MockitoBean
    private OpaqueTokenIntrospector tokenIntrospector;

    @Nested
    @DisplayName("GET /api/users/{id}")
    class GetUser {

        @Test
        @DisplayName("should return HTTP 401 when no token provided")
        void returnsUnauthorized() throws Exception {
            mockMvc.perform(get("/api/users/123"))
                .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("should return HTTP 403 when token lacks required scope")
        void returnsForbidden() throws Exception {
            mockMvc.perform(
                get("/api/users/123")
                    .with(opaqueToken().attributes(attrs -> attrs.put("scope", "some.other.scope")))
            ).andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("should return HTTP 200 when token has required scope")
        void returnsOk() throws Exception {
            when(userService.getUserById("123")).thenReturn(new UserResponse("123", "Alex"));

            mockMvc.perform(
                get("/api/users/123")
                    .with(opaqueToken().attributes(attrs -> attrs.put("scope", "required.scope")))
            ).andExpect(status().isOk());
        }
    }
}
```
