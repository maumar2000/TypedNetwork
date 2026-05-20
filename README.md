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

## ✨ Current Features

- ✅ Strongly-typed `Endpoint` (path, method, headers, query, body)
- ✅ Typed errors per endpoint via `Failure` and `mapError`
- ✅ `APIClient` actor as the single entry point
- ✅ `RequestBuilder` (internal) builds `URLRequest` from endpoints
- ✅ `NetworkSession` protocol decoupled from `URLSession`
- ✅ Pluggable `ResponseDecoder` (default: `JSONResponseDecoder`)
- ✅ Middleware chain with `next` transport closure
- ✅ `HTTPBody` with JSON and raw data support
- ✅ `AuthMiddleware` with token refresh on 401
- ✅ `MockRegistry` for endpoint-level mocking in tests
- ✅ Fully compatible with Swift Concurrency (`Sendable` safe)

---

## 🧱 Architecture

```
Endpoint → RequestBuilder → MiddlewareChain → NetworkSession → ResponseDecoder
                ↑                                    ↑
           MockRegistry (tests)              URLSession (default)
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

    func mapError(data: Data, response: HTTPURLResponse) -> APIError {
        // Decode or map server error payload
        try! JSONDecoder().decode(APIError.self, from: data)
    }
}
```

When `Failure` is `Never`, you do not need to implement `mapError`.

---

## 🚀 2. APIClient

`APIClient` builds the request, runs middlewares, executes the transport, decodes success responses, and maps errors.

```swift
let client = APIClient(
    baseURL: URL(string: "https://api.myapp.com")!,
    session: URLSession.shared,           // conforms to NetworkSession
    mockRegistry: nil,                    // optional, for tests
    middlewares: [AuthMiddleware(...)],
    decoder: JSONResponseDecoder()          // or a custom ResponseDecoder
)

let user: User = try await client.send(GetUser(id: 1))
```

On **2xx**, the client decodes `E.Response` using the injected decoder. On other status codes, it throws `endpoint.mapError(data:response:)`.

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

## 🔌 4. NetworkSession

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

## 🧩 5. ResponseDecoder

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

## 🧪 6. Middlewares

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
        AuthMiddleware(tokenStore: tokenStore, refresh: refreshToken)
    ]
)
```

---

## 🔐 7. AuthMiddleware

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

## 🧪 8. Testing

### Mock responses (no network)

Register mocked responses per endpoint type and path:

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

When a mock is registered, `APIClient` returns it immediately without hitting the session.

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

---

## 🧱 Clear Separation of Responsibilities

| Layer              | Responsibility                                      |
|--------------------|-----------------------------------------------------|
| `Endpoint`         | Request shape, response type, typed error mapping   |
| `RequestBuilder`   | Builds `URLRequest` from endpoint + base URL        |
| `HTTPBody`         | Encodes body and provides content type              |
| `Middleware`       | Intercepts/modifies requests and responses          |
| `NetworkSession`   | Executes HTTP transport                             |
| `ResponseDecoder`  | Decodes successful responses                        |
| `APIClient`        | Orchestrates the full pipeline                      |
| `MockRegistry`     | Returns canned responses in tests                   |

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

    func mapError(data: Data, response: HTTPURLResponse) -> APIError {
        (try? JSONDecoder().decode(APIError.self, from: data)) ?? APIError(message: "Unknown")
    }
}

let tokenStore = TokenStore(token: accessToken)

let client = APIClient(
    baseURL: URL(string: "https://api.myapp.com")!,
    middlewares: [
        AuthMiddleware(tokenStore: tokenStore, refresh: refreshAccessToken)
    ],
    decoder: JSONResponseDecoder()
)

let user = try await client.send(GetProfile())
```

---

## 📌 What's Next

Planned improvements:

- [x] Typed errors per endpoint
- [x] Mock registry for endpoint testing
- [x] Pluggable response decoding
- [x] Transport abstraction (`NetworkSession`)
- [ ] RetryMiddleware
- [ ] LoggingMiddleware
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
