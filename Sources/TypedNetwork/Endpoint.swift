import Foundation

public protocol Endpoint {
    associatedtype Response: Decodable
    associatedtype Failure: Error = Never

    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
    var body: Data? { get }

    func mapError(data: Data, response: HTTPURLResponse) -> Failure
}

public extension Endpoint {
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem] { [] }
    var body: Data? { nil }

    func mapError(data: Data, response: HTTPURLResponse) -> Failure {
        fatalError("Implement mapError if Failure != Never")
    }

    func makeRequest(baseURL: URL) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        request.httpBody = body

        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        return request
    }
}
