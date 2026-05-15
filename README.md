# TypedNetwork

**TypedNetwork** es una librería en Swift que permite construir requests HTTP **fuertemente tipados**, componibles y testeables, inspirada en patrones modernos de networking y pensada para integrarse fácil en apps iOS.

El objetivo es:

- Evitar strings sueltos para endpoints
- Tener requests fuertemente tipados
- Inyectar middlewares (auth, logging, retry, etc.)
- Separar construcción de request de su ejecución
- Facilitar testing sin tocar `URLSession`

---

## ✨ Features actuales

- ✅ `Request` fuertemente tipado
- ✅ `RequestBuilder` para crear requests de forma declarativa
- ✅ `HTTPSession` desacoplada de `URLSession`
- ✅ Sistema de `Middleware`
- ✅ Middleware de Auth de ejemplo
- ✅ Tests para middlewares
- ✅ Compatible con Swift Concurrency (`async/await`)

---

## 🧱 Arquitectura

```
RequestBuilder → Request → Middlewares → HTTPSession → URLSession
```

Cada capa tiene una responsabilidad clara.

---

## 🧩 1. Definición de un Request

Un request define **qué espera devolver**:

```swift
struct GetUserRequest: Request {
    typealias Response = User

    var path: String { "/user" }
    var method: HTTPMethod { .get }
}
```

---

## 🏗️ 2. Construcción con RequestBuilder

```swift
let request = RequestBuilder(GetUserRequest())
    .addQueryItem(name: "id", value: "123")
    .build(baseURL: baseURL)
```

Esto genera un `URLRequest` completo y tipado.

---

## 🧠 3. HTTPSession

`HTTPSession` es el encargado de ejecutar el request.

```swift
let session = HTTPSession(baseURL: baseURL)

let user: User = try await session.execute(request)
```

Internamente:

1. Construye el `URLRequest`
2. Pasa por todos los middlewares
3. Ejecuta el request
4. Decodifica el response tipado

---

## 🧪 4. Middlewares

Los middlewares pueden modificar el request antes de enviarlo.

```swift
public protocol Middleware {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}
```

Se inyectan en la sesión:

```swift
let session = HTTPSession(
    baseURL: baseURL,
    middlewares: [
        AuthMiddleware(tokenProvider: tokenProvider)
    ]
)
```

---

## 🔐 5. AuthMiddleware (ejemplo)

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

## 🧪 6. Testing de Middlewares

Los middlewares se testean **sin red**.

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

## 🧱 7. Separación clave

| Capa            | Responsabilidad                      |
|-----------------|--------------------------------------|
| `Request`       | Define endpoint y response tipado    |
| `RequestBuilder`| Construye el `URLRequest`           |
| `Middleware`    | Modifica/intercepta requests         |
| `HTTPSession`   | Ejecuta requests                    |

---

## 🚀 Ejemplo completo

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

## 📌 Qué viene después

Siguientes mejoras naturales:

- [ ] RetryMiddleware
- [ ] LoggingMiddleware
- [ ] CacheMiddleware
- [ ] Support para body encodable
- [ ] Soporte para headers en builder
- [ ] MockHTTPSession para tests de requests completos

---

## 🧠 Filosofía

TypedNetwork busca que el networking en iOS sea:

- Declarativo
- Tipado
- Testeable
- Extensible
- Compatible con Swift moderno

Sin frameworks externos. Solo Swift.
