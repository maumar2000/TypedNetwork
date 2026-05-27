import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol Middleware: Sendable {
    func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse)
}

struct MiddlewareChain: Sendable {
    private let middlewares: [any Middleware]

    init(_ middlewares: [any Middleware]) {
        self.middlewares = middlewares
    }

    func execute(
        request: URLRequest,
        transport: @Sendable @escaping (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {

        var current = transport

        for middleware in middlewares.reversed() {
            let next = current
            current = { request in
                try await middleware.intercept(request, next: next)
            }
        }

        return try await current(request)
    }
}
