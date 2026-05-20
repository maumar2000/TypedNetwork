# TypedNetwork

**TypedNetwork** is a Swift networking library for building **strongly-typed, composable, and testable** HTTP requests, designed to fit naturally into modern iOS apps and fully compatible with Swift Concurrency (Swift 6 ready).

The goals are:

- Eliminate stringly-typed endpoints
- Model requests and responses with strong types
- Map HTTP errors to typed `Failure` values per endpoint
- Inject middlewares (auth, logging, retry, etc.)
- Swap transport and decoding for tests without touching production code
- Make networking easy to test without real network calls

---

## 📦 Installation

### Swift Package Manager

Add TypedNetwork to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/maumar2000/TypedNetwork.git", from: "0.1.0")
]
```

Then add the library to your target:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "TypedNetwork", package: "TypedNetwork")
        ]
    )
]
```

### Xcode

1. **File → Add Package Dependencies…**
2. Enter `https://github.com/maumar2000/TypedNetwork.git`
3. Choose version **0.1.0** (or *Up to Next Major*)
4. Add the **TypedNetwork** product to your app target

```swift
import TypedNetwork
```

---

## ✨ Current Features

- ✅ Strongly-typed `Endpoint` (path, method, headers, query, body, timeout)
- ✅ Typed errors per endpoint via `Failure` and `mapError`
- ✅ Unified `NetworkError` (`transport`, `decoding`, `endpoint`)
- ✅ `APIClient` actor as the single entry point
- ✅ `RequestBuilder` (internal) builds `URLRequest` from endpoints
- ✅ `RequestModifier` for composable request customization
- ✅ `NetworkSession` protocol decoupled from `URLSession`
- ✅ Pluggable `ResponseDecoder` (default: `JSONResponseDecoder`)
- ✅ `EmptyResponse` for 204 / no-body endpoints
- ✅ Middleware chain with `next` transport closure
- ✅ `HTTPBody` with JSON and raw data support
- ✅ `AuthMiddleware` with token refresh on 401
- ✅ `RetryMiddleware` with configurable `RetryPolicy` (HTTP-status based)
- ✅ `LoggingMiddleware` for request/response diagnostics
- ✅ `MockMiddleware` and `MockRegistry` for test doubles
- ✅ Fully compatible with Swift Concurrency (`Sendable` safe)

---

## 🧱 Architecture

```
Endpoint → RequestBuilder → MiddlewareChain → NetworkSession → ResponseDecoder
                ↑                    ↑
        RequestModifier      MockMiddleware / Auth / Retry / Logging
                ↑
           MockRegistry (tests, optional)
```

Each layer has a single, clear responsibility.

---

## 🧩 1. Defining an Endpoint

An endpoint describes the request and the types for success and failure.

```swift
struct GetUser: Endpoint {
    typealias Response = User
    typealias Failure = APIError  // optional; defaults to Never

    let id: Int

    var path: String { "/users/\(id)" }
    var method: HTTPMethod { .get }

    // Optional — defaults provided by protocol extension
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem] { [] }
    var body: HTTPBody? { nil }
    var timeout: Duration? { .seconds(30) }

    func mapError(data: Data, response: HTTPURLResponse) -> APIError {
        // Decode or map server error payload
        try! JSONDecoder().decode(APIError.self, from: data)
    }
}
```

When `Failure` is `Never`, you do not need to implement `mapError`.

### Empty responses (204)

Use `EmptyResponse` when the API returns no body:

```swift
struct DeleteUser: Endpoint {
    typealias Response = EmptyResponse
    typealias Failure = Never

    let id: Int

    var path: String { "/users/\(id)" }
    var method: HTTPMethod { .delete }
}
```

`JSONResponseDecoder` returns `EmptyResponse()` automatically when `E.Response` is `EmptyResponse`.

---

## 🚀 2. APIClient

`APIClient` builds the request, runs middlewares, executes the transport, decodes success responses, and maps errors.

```swift
let client = APIClient(
    baseURL: URL(string: "https://api.myapp.com")!,
    session: URLSession.shared,              // conforms to NetworkSession
    mockRegistry: nil,                       // optional, for tests
    middlewares: [
        LoggingMiddleware(),
        AuthMiddleware(tokenStore: tokenStore, refresh: refreshToken),
        RetryMiddleware(policy: .default)
    ],
    requestModifiers: [UserAgentModifier()], // optional
    decoder: JSONResponseDecoder()           // or a custom ResponseDecoder
)

let user: User = try await client.send(GetUser(id: 1))
```

On **2xx**, the client decodes `E.Response` using the injected decoder.

On failure, `APIClient` throws `NetworkError`:

| Case | When |
|------|------|
| `.transport(URLError)` | Network or invalid HTTP response |
| `.decoding(Error)` | Response body could not be decoded |
| `.endpoint(Error)` | Non-2xx status; wraps `endpoint.mapError(...)` |

```swift
do {
    let user = try await client.send(GetUser(id: 1))
} catch let error as NetworkError {
    switch error {
    case .transport(let urlError):
        print(urlError)
    case .decoding(let underlying):
        print(underlying)
    case .endpoint(let apiError):
        print(apiError) // your typed Failure
    }
}
```

---

## 📦 3. HTTPBody (JSON & Raw Data)

`HTTPBody` encodes request bodies and sets `Content-Type`.

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

Headers and query items are set on the endpoint itself:

```swift
var headers: [String: String] { ["Authorization": "Bearer \(token)"] }
var queryItems: [URLQueryItem] { [URLQueryItem(name: "page", value: "1")] }
```

---

## 🔧 4. RequestModifier

`RequestModifier` lets you apply cross-cutting changes to every request without duplicating logic in each endpoint.

```swift
public protocol RequestModifier: Sendable {
    func modify(_ request: URLRequest) -> URLRequest
}

struct UserAgentModifier: RequestModifier {
    func modify(_ request: URLRequest) -> URLRequest {
        var modified = request
        modified.setValue("MyApp/1.0", forHTTPHeaderField: "User-Agent")
        return modified
    }
}
```

Modifiers run inside `RequestBuilder` after the endpoint fields (method, headers, body, timeout) are applied.

---

## 🔌 5. NetworkSession

`NetworkSession` abstracts the transport layer so you can inject a stub in tests.

```swift
public protocol NetworkSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}
```

Example stub for unit tests:

```swift
final class StubSession: NetworkSession {
    let data: Data
    let response: URLResponse

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        (data, response)
    }
}
```

---

## 🧩 6. ResponseDecoder

`ResponseDecoder` controls how successful responses are turned into `E.Response`. The default implementation uses `JSONDecoder`.

```swift
public protocol ResponseDecoder: Sendable {
    func decode<E: Endpoint>(
        data: Data,
        response: HTTPURLResponse,
        for endpoint: E
    ) throws -> E.Response
}
```

Inject a custom decoder when you need date strategies, key decoding, or non-JSON payloads:

```swift
let client = APIClient(
    baseURL: baseURL,
    decoder: JSONResponseDecoder(decoder: myJSONDecoder)
)
```

The decoder receives the raw `Data`, the `HTTPURLResponse`, and the endpoint, so you can branch on status headers or endpoint type if needed.

---

## 🧪 7. Middlewares

Middlewares wrap the transport in an onion chain. Each middleware receives the request and a `next` closure that continues the chain.

```swift
public protocol Middleware: Sendable {
    func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse)
}
```

Register them on `APIClient`:

```swift
let client = APIClient(
    baseURL: baseURL,
    middlewares: [
        LoggingMiddleware(),
        AuthMiddleware(tokenStore: tokenStore, refresh: refreshToken),
        RetryMiddleware(policy: RetryPolicy(
            maxRetries: 2,
            shouldRetry: { (500...599).contains($0.statusCode) }
        ))
    ]
)
```

Retry decisions are based on `HTTPURLResponse`, not thrown errors.

---

## 🔐 8. AuthMiddleware

Adds a Bearer token and retries once after refreshing on `401`.

```swift
let tokenStore = TokenStore(token: "initial-token")

let client = APIClient(
    baseURL: baseURL,
    middlewares: [
        AuthMiddleware(
            tokenStore: tokenStore,
            refresh: { try await fetchNewToken() }
        )
    ]
)
```

---

## 🔁 9. RetryMiddleware

Retries when a `RetryPolicy` predicate matches the `HTTPURLResponse`. Waits between attempts using Swift's `Duration`.

```swift
let policy = RetryPolicy(
    maxRetries: 3,
    delay: .seconds(1),
    shouldRetry: { response in
        (500...599).contains(response.statusCode)
    }
)

let client = APIClient(
    baseURL: baseURL,
    middlewares: [RetryMiddleware(policy: policy)]
)
```

| Field | Role |
|-------|------|
| `maxRetries` | Extra attempts after the first failure (not total request count) |
| `delay` | Pause before each retry (default: 1 second) |
| `shouldRetry` | Predicate on `HTTPURLResponse`; when it returns `false`, the last response is returned |

Order middlewares deliberately: e.g. put `RetryMiddleware` **after** `AuthMiddleware` so retries run with a fresh token when auth refresh applies.

---

## 📋 10. LoggingMiddleware

Logs outgoing requests and incoming responses without touching business logic.

```swift
let client = APIClient(
    baseURL: baseURL,
    middlewares: [
        LoggingMiddleware() // defaults to print(_:)
    ]
)

// Custom sink (e.g. os.Logger)
LoggingMiddleware { message in
    logger.debug("\(message)")
}
```

Output includes method, URL, headers, status code, and elapsed duration.

---

## 🧪 11. Testing

### MockRegistry (endpoint-level)

Register typed responses per endpoint; `APIClient` returns them before any network call.

```swift
let mock = MockRegistry()
await mock.register(GetUser(id: 1), response: User(id: 1, name: "Mocked"))

let client = APIClient(
    baseURL: URL(string: "https://test.com")!,
    mockRegistry: mock
)

let user = try await client.send(GetUser(id: 1))
#expect(user.name == "Mocked")
```

### MockMiddleware (request-level)

Short-circuit the middleware chain without a registry — useful in app or integration tests:

```swift
let client = APIClient(
    baseURL: URL(string: "https://test.com")!,
    middlewares: [
        MockMiddleware { request in
            guard request.url?.path.hasSuffix("/users") == true else { return nil }
            let data = #"{"id":1,"name":"Mocked"}"#.data(using: .utf8)!
            let http = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, http)
        }
    ]
)
```

Return `nil` from the handler to fall through to the real transport.

### Stub session and custom decoder

```swift
let session = StubSession(data: jsonData, response: httpResponse)
let decoder = StubDecoder(expected: myResponse)

let client = APIClient(
    baseURL: baseURL,
    session: session,
    decoder: decoder
)
```

### Middleware in isolation

Test middleware by calling `intercept` with a stub `next` that returns fixed `(Data, HTTPURLResponse)` values—no real network required.

```swift
let policy = RetryPolicy(
    maxRetries: 2,
    delay: .seconds(0),
    shouldRetry: { $0.statusCode == 500 }
)
let middleware = RetryMiddleware(policy: policy)

let (data, response) = try await middleware.intercept(request) { _ in
    // return synthetic (Data, HTTPURLResponse) per attempt
}
```

---

## 🧱 Clear Separation of Responsibilities

| Layer | Responsibility |
|-------|----------------|
| `Endpoint` | Request shape, response type, timeout, typed error mapping |
| `RequestBuilder` | Builds `URLRequest` from endpoint + base URL + modifiers |
| `RequestModifier` | Cross-cutting `URLRequest` customization |
| `HTTPBody` | Encodes body and provides content type |
| `Middleware` | Intercepts/modifies requests and responses |
| `RetryPolicy` | Configures retry count, delay, and retry predicate |
| `NetworkSession` | Executes HTTP transport |
| `ResponseDecoder` | Decodes successful responses |
| `NetworkError` | Unified error surface from `APIClient` |
| `APIClient` | Orchestrates the full pipeline |
| `MockRegistry` / `MockMiddleware` | Returns canned responses in tests |

---

## 🚀 Complete Example

```swift
struct APIError: Decodable, Error, Sendable {
    let message: String
}

struct GetProfile: Endpoint {
    typealias Response = User
    typealias Failure = APIError

    var path: String { "/me" }
    var method: HTTPMethod { .get }
    var timeout: Duration? { .seconds(15) }

    func mapError(data: Data, response: HTTPURLResponse) -> APIError {
        (try? JSONDecoder().decode(APIError.self, from: data)) ?? APIError(message: "Unknown")
    }
}

let tokenStore = TokenStore(token: accessToken)

let client = APIClient(
    baseURL: URL(string: "https://api.myapp.com")!,
    middlewares: [
        LoggingMiddleware(),
        AuthMiddleware(tokenStore: tokenStore, refresh: refreshAccessToken),
        RetryMiddleware(policy: RetryPolicy(
            maxRetries: 2,
            delay: .seconds(1),
            shouldRetry: { (500...599).contains($0.statusCode) }
        ))
    ],
    requestModifiers: [UserAgentModifier()],
    decoder: JSONResponseDecoder()
)

do {
    let user = try await client.send(GetProfile())
} catch let error as NetworkError {
    // handle transport / decoding / endpoint uniformly
    print(error)
}
```

---

## 📌 What's Next

- [x] Typed errors per endpoint
- [x] Unified `NetworkError`
- [x] Mock registry and `MockMiddleware`
- [x] Pluggable response decoding
- [x] `EmptyResponse` support
- [x] Transport abstraction (`NetworkSession`)
- [x] `RequestModifier`
- [x] Per-endpoint timeout
- [x] `AuthMiddleware`
- [x] `RetryMiddleware`
- [x] `LoggingMiddleware`
- [ ] CacheMiddleware

---

## 🧠 Philosophy

TypedNetwork aims to make iOS networking:

- Declarative
- Strongly typed
- Testable
- Extensible
- Aligned with modern Swift

No external dependencies. Just Swift.

**Platforms:** iOS 16+, macOS 13+ (Swift 5.9, Strict Concurrency).

See [CHANGELOG.md](CHANGELOG.md) for release history.
