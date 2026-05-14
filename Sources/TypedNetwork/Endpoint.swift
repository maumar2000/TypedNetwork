import Foundation

public protocol Endpoint: Sendable {
    associatedtype Response: Decodable & Sendable
    associatedtype Failure: Error & Sendable = Never

    var path: String { get }
    var method: HTTPMethod { get }

    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
    var body: HTTPBody? { get }

    func mapError(data: Data, response: HTTPURLResponse) -> Failure
}

public extension Endpoint {
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem] { [] }
    var body: HTTPBody? { nil }

    func mapError(data: Data, response: HTTPURLResponse) -> Failure {
        fatalError("Implement mapError if Failure != Never")
    }

    func makeRequest(baseURL: URL) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        if let body {
            request.httpBody = try body.encode()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        return request
    }
}
