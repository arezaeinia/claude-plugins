# Client Test Template (Kotlin + JUnit 5 + Mockito)

Tests for outbound HTTP clients using WireMock (`@WireMockTest`). Load JSON responses from fixture files — never inline large JSON strings in test code.

```kotlin
package com.example.project.client

import com.github.tomakehurst.wiremock.client.WireMock.equalTo
import com.github.tomakehurst.wiremock.client.WireMock.equalToJson
import com.github.tomakehurst.wiremock.client.WireMock.get
import com.github.tomakehurst.wiremock.client.WireMock.getRequestedFor
import com.github.tomakehurst.wiremock.client.WireMock.okJson
import com.github.tomakehurst.wiremock.client.WireMock.post
import com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor
import com.github.tomakehurst.wiremock.client.WireMock.serverError
import com.github.tomakehurst.wiremock.client.WireMock.stubFor
import com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo
import com.github.tomakehurst.wiremock.client.WireMock.verify
import com.github.tomakehurst.wiremock.junit5.WireMockRuntimeInfo
import com.github.tomakehurst.wiremock.junit5.WireMockTest
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.Mock
import org.mockito.junit.jupiter.MockitoExtension
import org.mockito.kotlin.whenever

@WireMockTest
@ExtendWith(MockitoExtension::class)
class UserClientTest {

    @Mock
    private lateinit var accessTokenManager: AccessTokenManager

    private lateinit var client: UserClient

    private val tokenId = "test-token-id"
    private val token = "test-access-token"

    @BeforeEach
    fun setUp(wm: WireMockRuntimeInfo) {
        client = UserClient(
            baseUrl = "http://localhost:${wm.httpPort}",
            accessTokenManager = accessTokenManager,
            tokenId = tokenId
        )
        whenever(accessTokenManager.getAccessToken(tokenId).accessToken).thenReturn(token)
    }

    // GET — no request body
    @Test
    @DisplayName("returns parsed response on success")
    fun returnsParsedResponse() {
        val responseJson = javaClass.getResourceAsStream("/fixtures/clients/user-client/success-response.json")!!
            .readBytes().toString(Charsets.UTF_8)

        stubFor(
            get(urlEqualTo("/api/users?id=123"))
                .withHeader("Authorization", equalTo("Bearer $token"))
                .willReturn(okJson(responseJson))
        )

        val result = client.getUser("123")

        assertThat(result.name).isEqualTo("Alex")
        verify(getRequestedFor(urlEqualTo("/api/users?id=123")))
    }

    // POST — stub and verify the full request body from a fixture file
    @Test
    @DisplayName("creates resource and returns parsed response")
    fun createsResource() {
        val requestJson = javaClass.getResourceAsStream("/fixtures/clients/user-client/create-request.json")!!
            .readBytes().toString(Charsets.UTF_8)
        val responseJson = javaClass.getResourceAsStream("/fixtures/clients/user-client/create-success.json")!!
            .readBytes().toString(Charsets.UTF_8)

        stubFor(
            post(urlEqualTo("/api/users"))
                .withHeader("Authorization", equalTo("Bearer $token"))
                .withRequestBody(equalToJson(requestJson))
                .willReturn(okJson(responseJson))
        )

        val result = client.createUser(UserCreateRequest("Alex", "alex@example.com"))

        assertThat(result.id).isEqualTo("123")
        verify(
            postRequestedFor(urlEqualTo("/api/users"))
                .withRequestBody(equalToJson(requestJson))
        )
    }

    @Test
    @DisplayName("returns empty list on server error")
    fun returnsEmptyListOnError() {
        stubFor(
            get(urlEqualTo("/api/users?id=123"))
                .willReturn(serverError())
        )

        val result = client.getUsers(setOf("123"))

        assertThat(result).isEmpty()
    }
}
```

## Fixture file location

Store JSON responses under `src/test/resources/fixtures/clients/<client-name>/<scenario>.json`:

```
src/test/resources/
└── fixtures/
    └── clients/
        └── user-client/
            ├── success-response.json
            ├── error-response.json
            ├── create-request.json      ← request body for POST/PUT/PATCH
            └── create-success.json      ← response body
```

Example `success-response.json`:

```json
{
  "users": [
    { "id": "123", "name": "Alex", "email": "alex@example.com" }
  ],
  "total": 1
}
```

## Dependency

```xml
<dependency>
    <groupId>org.wiremock</groupId>
    <artifactId>wiremock-standalone</artifactId>
    <version>3.x.x</version>
    <scope>test</scope>
</dependency>
```

## Notes

- `@WireMockTest` starts a real HTTP server on a random port per test class — no Spring context needed
- Inject `WireMockRuntimeInfo` into `@BeforeEach` to get the port and build the client's base URL
- Stubs are reset automatically between tests by `@WireMockTest`
- Use `verify(getRequestedFor(...))` to assert the request was actually made
- **POST/PUT/PATCH**: load the full request body from a fixture file and use `withRequestBody(equalToJson(requestJson))` — stricter than field-by-field matching and keeps the contract in one place
- **GET**: no request body — omit `withRequestBody` entirely
