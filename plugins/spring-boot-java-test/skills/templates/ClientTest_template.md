# Client Test Template

Tests for outbound HTTP clients using WireMock (`@WireMockTest`). Load JSON responses from fixture files — never inline large JSON strings in test code.

```java
package com.example.project.client;

import com.github.tomakehurst.wiremock.client.WireMock;
import com.github.tomakehurst.wiremock.junit5.WireMockRuntimeInfo;
import com.github.tomakehurst.wiremock.junit5.WireMockTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

import static com.github.tomakehurst.wiremock.client.WireMock.equalTo;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.getRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.okJson;
import static com.github.tomakehurst.wiremock.client.WireMock.serverError;
import static com.github.tomakehurst.wiremock.client.WireMock.stubFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo;
import static com.github.tomakehurst.wiremock.client.WireMock.verify;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@WireMockTest
@ExtendWith(MockitoExtension.class)
class UserClientTest {

    @Mock
    private AccessTokenManager accessTokenManager;

    private UserClient client;

    private static final String TOKEN_ID = "test-token-id";
    private static final String TOKEN = "test-access-token";

    @BeforeEach
    void setUp(WireMockRuntimeInfo wm) {
        client = new UserClient(
            "http://localhost:" + wm.getHttpPort(),
            accessTokenManager,
            TOKEN_ID
        );
        when(accessTokenManager.getAccessToken(TOKEN_ID).getAccessToken()).thenReturn(TOKEN);
    }

    @Test
    @DisplayName("returns parsed response on success")
    void returnsParsedResponse() throws IOException {
        var responseJson = new String(
            UserClientTest.class.getResourceAsStream("/fixtures/clients/user-client/success-response.json").readAllBytes(),
            StandardCharsets.UTF_8
        );

        stubFor(
            get(urlEqualTo("/api/users?id=123"))
                .withHeader("Authorization", equalTo("Bearer " + TOKEN))
                .willReturn(okJson(responseJson))
        );

        var result = client.getUser("123");

        assertThat(result.getName()).isEqualTo("Alex");
        verify(getRequestedFor(urlEqualTo("/api/users?id=123")));
    }

    @Test
    @DisplayName("returns empty list on server error")
    void returnsEmptyListOnError() {
        stubFor(
            get(urlEqualTo("/api/users?id=123"))
                .willReturn(serverError())
        );

        var result = client.getUsers(Set.of("123"));

        assertThat(result).isEmpty();
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
- Inject `WireMockRuntimeInfo` into `@BeforeEach` to get the port and build the client's base URL
- Stubs are reset automatically between tests by `@WireMockTest`
- Use `verify(getRequestedFor(...))` to assert the request was actually made
