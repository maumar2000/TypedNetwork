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
}
