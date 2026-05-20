# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-20

### Added

- Strongly-typed `Endpoint` protocol with associated `Response` and `Failure` types
- `APIClient` actor as the single orchestration entry point
- `RequestBuilder` to build `URLRequest` from endpoints and base URL
- `HTTPMethod`, `HTTPBody` (JSON and raw data), headers, query items, and per-endpoint `timeout`
- `NetworkSession` abstraction with `URLSession` conformance
- Pluggable `ResponseDecoder` with default `JSONResponseDecoder`
- `EmptyResponse` for 204 / no-body endpoints
- Unified `NetworkError` (`transport`, `decoding`, `endpoint`) mapped by `APIClient`
- Middleware chain with `next` transport closure pattern
- `AuthMiddleware` with Bearer token injection and refresh on 401
- `RetryMiddleware` and `RetryPolicy` (HTTP-status based retries with `Duration` delay)
- `LoggingMiddleware` for request URL, method, headers, status, and duration
- `MockMiddleware` and `MockRegistry` for test doubles without real network calls
- `RequestModifier` integrated into `RequestBuilder`
- `TokenStore` actor for auth token storage
- Swift Testing test suite with Strict Concurrency enabled

### Requirements

- iOS 16+
- macOS 13+
- Swift 5.9+

[0.1.0]: https://github.com/maumar2000/TypedNetwork/releases/tag/0.1.0
