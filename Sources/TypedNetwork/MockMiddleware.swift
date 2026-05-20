import Foundation

public struct MockMiddleware: Middleware {

    private let handler: @Sendable (URLRequest) async -> (Data, HTTPURLResponse)?

    public init(
        handler: @escaping @Sendable (URLRequest) async -> (Data, HTTPURLResponse)?
    ) {
        self.handler = handler
    }

    public func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        if let mock = await handler(request) {
            return mock
        }
        return try await next(request)
    }
}
