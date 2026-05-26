import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct LoggingMiddleware: Middleware {

    private let log: @Sendable (String) -> Void

    public init(log: @escaping @Sendable (String) -> Void = { print($0) }) {
        self.log = log
    }

    public func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {

        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<unknown>"
        let headers = request.allHTTPHeaderFields ?? [:]

        log("→ \(method) \(url)")
        log("  headers: \(headers)")

        let clock = ContinuousClock()
        let start = clock.now

        let (data, response) = try await next(request)

        let elapsed = clock.now - start
        log("← \(response.statusCode) (\(elapsed))")

        return (data, response)
    }
}
