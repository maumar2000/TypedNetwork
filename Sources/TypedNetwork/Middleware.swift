import Foundation

public protocol Middleware: Sendable {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}

public struct MiddlewareChain {
    private let middlewares: [Middleware]

    public init(_ middlewares: [Middleware]) {
        self.middlewares = middlewares
    }

    func run(_ request: URLRequest) async throws -> URLRequest {
        var req = request
        for middleware in middlewares {
            req = try await middleware.intercept(req)
        }
        return req
    }
}
