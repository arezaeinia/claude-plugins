# Client Test Template

Tests for outbound HTTP clients using `MockRestServiceServer`. Load JSON responses from fixture files — never inline large JSON strings in test code.

```kotlin
package com.example.project.client

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.mockk
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.test.web.client.MockRestServiceServer
import org.springframework.test.web.client.match.MockRestRequestMatchers.header
import org.springframework.test.web.client.match.MockRestRequestMatchers.method
import org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo
import org.springframework.test.web.client.response.MockRestResponseCreators.withServerError
import org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess
import org.springframework.web.client.RestClient
import org.springframework.web.client.RestTemplate
import org.zalando.spring.oauth2.client.core.AccessTokenManager

class UserClientTest : FunSpec({

    val accessTokenManager = mockk<AccessTokenManager>()
    val restTemplate = RestTemplate()
    val mockServer = MockRestServiceServer.createServer(restTemplate)
    val restClient = RestClient.create(restTemplate)

    val endpoint = "http://localhost/api/users"
    val tokenId = "test-token-id"
    val token = "test-access-token"

    val client = UserClient(
        restClient = restClient,
        accessTokenManager = accessTokenManager,
        endpoint = endpoint,
        tokenId = tokenId,
    )

    beforeTest {
        clearAllMocks()
        mockServer.reset()
        every { accessTokenManager.getAccessToken(tokenId).accessToken } returns token
    }

    test("returns parsed response on success") {
        val responseJson = UserClientTest::class.java
            .getResource("/fixtures/user-client/success-response.json")!!
            .readText()

        mockServer
            .expect(requestTo("$endpoint?id=123"))
            .andExpect(method(HttpMethod.GET))
            .andExpect(header("Authorization", "Bearer $token"))
            .andRespond(withSuccess(responseJson, MediaType.APPLICATION_JSON))

        val result = client.getUser("123")

        result.name shouldBe "Alex"
        mockServer.verify()
    }

    test("returns empty list on server error") {
        mockServer
            .expect(requestTo("$endpoint?id=123"))
            .andExpect(method(HttpMethod.GET))
            .andRespond(withServerError())

        val result = client.getUsers(setOf("123"))

        result.shouldBeEmpty()
        mockServer.verify()
    }
})
```

## Fixture file location

Store JSON responses under `src/test/resources/fixtures/<client-name>/<scenario>.json`:

```
src/test/resources/
└── fixtures/
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

## Notes

- Always call `mockServer.verify()` at the end of each test to assert all expected requests were made
- `mockServer.reset()` in `beforeTest` ensures expectations don't bleed between tests
