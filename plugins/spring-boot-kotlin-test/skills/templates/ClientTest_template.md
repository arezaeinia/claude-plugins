# Client Test Template

Tests for outbound HTTP clients using WireMock (`@WireMockTest`). Load JSON responses from fixture files — never inline large JSON strings in test code.

```kotlin
package com.example.project.client

import com.github.tomakehurst.wiremock.client.WireMock.get
import com.github.tomakehurst.wiremock.client.WireMock.getRequestedFor
import com.github.tomakehurst.wiremock.client.WireMock.okJson
import com.github.tomakehurst.wiremock.client.WireMock.serverError
import com.github.tomakehurst.wiremock.client.WireMock.stubFor
import com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo
import com.github.tomakehurst.wiremock.client.WireMock.verify
import com.github.tomakehurst.wiremock.junit5.WireMockRuntimeInfo
import com.github.tomakehurst.wiremock.junit5.WireMockTest
import io.kotest.core.spec.style.FunSpec
import io.kotest.extensions.spring.SpringExtension
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk

@WireMockTest
class UserClientTest(wmInfo: WireMockRuntimeInfo) : FunSpec() {

    override fun extensions() = listOf(SpringExtension)

    private val accessTokenManager = mockk<AccessTokenManager>()
    private val token = "test-access-token"
    private val tokenId = "test-token-id"

    private val client = UserClient(
        baseUrl = "http://localhost:${wmInfo.httpPort}",
        accessTokenManager = accessTokenManager,
        tokenId = tokenId,
    )

    init {
        beforeTest {
            clearAllMocks()
            every { accessTokenManager.getAccessToken(tokenId).accessToken } returns token
        }

        test("returns parsed response on success") {
            val responseJson = UserClientTest::class.java
                .getResource("/fixtures/clients/user-client/success-response.json")!!
                .readText()

            stubFor(
                get(urlEqualTo("/api/users?id=123"))
                    .withHeader("Authorization", com.github.tomakehurst.wiremock.client.WireMock.equalTo("Bearer $token"))
                    .willReturn(okJson(responseJson))
            )

            val result = client.getUser("123")

            result.name shouldBe "Alex"
            verify(getRequestedFor(urlEqualTo("/api/users?id=123")))
        }

        test("returns empty list on server error") {
            stubFor(
                get(urlEqualTo("/api/users?id=123"))
                    .willReturn(serverError())
            )

            val result = client.getUsers(setOf("123"))

            result.shouldBeEmpty()
        }
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
            └── error-response.json
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
- Pass `WireMockRuntimeInfo` to get the port and build the client's base URL in the constructor
- Stubs are reset automatically between tests by `@WireMockTest`
- Use `verify(getRequestedFor(...))` to assert the request was actually made
