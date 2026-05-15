# TypedNetwork

**TypedNetwork** is a Swift networking library for building **strongly-typed, composable, and testable** HTTP requests, designed to integrate naturally into modern iOS apps.

The goals are:

- Eliminate stringly-typed endpoints
- Model requests with strong types
- Inject middlewares (auth, logging, retry, etc.)
- Separate request construction from execution
- Make networking easy to test without touching `URLSession`

---

## ✨ Current Features

- ✅ Strongly-typed `Request`
- ✅ Declarative `RequestBuilder`
- ✅ `HTTPSession` decoupled from `URLSession`
- ✅ Middleware system
- ✅ Example Auth middleware
- ✅ Middleware unit tests (no network)
- ✅ Fully compatible with Swift Concurrency (`async/await`)

---

## 🧱 Architecture

```
RequestBuilder → Request → Middlewares → HTTPSession → URLSession
```

Each layer has a single, clear responsibility.

---

## 🧩 1. Defining a Request

A request defines **what it expects to return**:

```swift
struct GetUserRequest: Request {
    typealias Response = User

    var path: String { "/user" }
    var method: HTTPMethod { .get }
}
```

---

## 🏗️ 2. Building with RequestBuilder

```swift
let request = RequestBuilder(GetUserRequest())
    .addQueryItem(name: "id", value: "123")
    .build(baseURL: baseURL)
```

This produces a complete, typed `URLRequest`.

---

## 🧠 3. HTTPSession

`HTTPSession` is responsible for executing requests.

```swift
let session = HTTPSession(baseURL: baseURL)

let user: User = try await session.execute(request)
```

Internally it:

1. Builds the `URLRequest`
2. Passes it through all middlewares
3. Executes the request
4. Decodes the typed response

---

## 🧪 4. Middlewares

Middlewares can intercept and modify a request before it is sent.

```swift
public protocol Middleware {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}
```

They are injected into the session:

```swift
let session = HTTPSession(
    baseURL: baseURL,
    middlewares: [
        AuthMiddleware(tokenProvider: tokenProvider)
    ]
)
```

---

## 🔐 5. AuthMiddleware Example

```swift
final class AuthMiddleware: Middleware {
    private let tokenProvider: TokenProvider

    init(tokenProvider: TokenProvider) {
        self.tokenProvider = tokenProvider
    }

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        let token = try await tokenProvider.token()
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
```

---

## 🧪 6. Testing Middlewares (No Network)

Middlewares are tested without performing real network calls.

```swift
func test_authMiddleware_addsAuthorizationHeader() async throws {
    let tokenProvider = MockTokenProvider(token: "abc123")
    let middleware = AuthMiddleware(tokenProvider: tokenProvider)

    let request = URLRequest(url: URL(string: "https://example.com")!)
    let result = try await middleware.intercept(request)

    XCTAssertEqual(
        result.value(forHTTPHeaderField: "Authorization"),
        "Bearer abc123"
    )
}
```

---

## 🧱 7. Clear Separation of Responsibilities

| Layer           | Responsibility                          |
|-----------------|------------------------------------------|
| `Request`       | Defines endpoint and typed response      |
| `RequestBuilder`| Builds the `URLRequest`                 |
| `Middleware`    | Intercepts/modifies requests             |
| `HTTPSession`   | Executes requests                       |

---

## 🚀 Complete Example

```swift
let session = HTTPSession(
    baseURL: URL(string: "https://api.myapp.com")!,
    middlewares: [
        AuthMiddleware(tokenProvider: tokenProvider)
    ]
)

let request = RequestBuilder(GetUserRequest())
    .addQueryItem(name: "id", value: "123")
    .build()

let user: User = try await session.execute(request)
```

---

## 📌 What’s Next

Natural next improvements:

- [ ] RetryMiddleware
- [ ] LoggingMiddleware
- [ ] CacheMiddleware
- [ ] Encodable body support
- [ ] Header support in builder
- [ ] MockHTTPSession for full request testing

---

## 🧠 Philosophy

TypedNetwork aims to make iOS networking:

- Declarative
- Strongly typed
- Testable
- Extensible
- Aligned with modern Swift

No external dependencies. Just Swift.
