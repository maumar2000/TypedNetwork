# TypedNetwork

**TypedNetwork** is a Swift networking library for building **strongly-typed, composable, and testable** HTTP requests, designed to fit naturally into modern iOS apps and fully compatible with Swift Concurrency (Swift 6 ready).

The goals are:

- Eliminate stringly-typed endpoints
- Model requests with strong types
- Inject middlewares (auth, logging, retry, etc.)
- Separate request construction from execution
- Make networking easy to test without touching `URLSession`

---

## ✨ Current Features

- ✅ Strongly-typed `Endpoint`
- ✅ Declarative `RequestBuilder`
- ✅ `HTTPSession` decoupled from `URLSession`
- ✅ Middleware system
- ✅ `HTTPBody` with JSON and raw data support
- ✅ Example Auth middleware
- ✅ Middleware unit tests (no network)
- ✅ Fully compatible with Swift Concurrency (`Sendable` safe)

---

## 🧱 Architecture

```
RequestBuilder → Endpoint → Middlewares → HTTPSession → URLSession
```

Each layer has a single, clear responsibility.

---

## 🧩 1. Defining an Endpoint

An endpoint defines **what it expects to return** and optionally how it sends data.

```swift
struct GetUser: Endpoint {
    typealias Response = User

    var path: String { "/user" }
    var method: HTTPMethod { .get }
}
```

---

## 🏗️ 2. Building a Request

```swift
let request = RequestBuilder(GetUser())
    .addQueryItem(name: "id", value: "123")
    .build(baseURL: baseURL)
```

This produces a complete, typed `URLRequest`.

---

## 📦 3. HTTPBody (JSON & Raw Data)

`HTTPBody` allows endpoints to send data safely and ergonomically.

### JSON body

```swift
struct CreateUser: Endpoint {
    typealias Response = User

    var path: String { "/users" }
    var method: HTTPMethod { .post }
    var body: HTTPBody { .json(UserDTO(name: "Mauri")) }
}
```

### Raw data body (images, files, binaries)

```swift
var body: HTTPBody {
    .data(imageData, contentType: "image/png")
}
```

`HTTPBody` automatically provides the correct `Content-Type` to the request.

---

## 🧠 4. HTTPSession

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

## 🧪 5. Middlewares

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

## 🔐 6. AuthMiddleware Example

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

## 🧪 7. Testing Middlewares (No Network)

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

## 🧱 Clear Separation of Responsibilities

| Layer            | Responsibility                          |
|------------------|------------------------------------------|
| `Endpoint`       | Defines endpoint and typed response      |
| `RequestBuilder` | Builds the `URLRequest`                 |
| `HTTPBody`       | Encodes body and provides content type  |
| `Middleware`     | Intercepts/modifies requests             |
| `HTTPSession`    | Executes requests                       |

---

## 🚀 Complete Example

```swift
let session = HTTPSession(
    baseURL: URL(string: "https://api.myapp.com")!,
    middlewares: [
        AuthMiddleware(tokenProvider: tokenProvider)
    ]
)

let request = RequestBuilder(GetUser())
    .addQueryItem(name: "id", value: "123")
    .build()

let user: User = try await session.execute(request)
```

---

## 📌 What’s Next

Planned improvements:

- [ ] Typed errors per endpoint
- [ ] RetryMiddleware
- [ ] LoggingMiddleware
- [ ] CacheMiddleware
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
