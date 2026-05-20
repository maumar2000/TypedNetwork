import Foundation

public protocol RequestModifier: Sendable {
    func modify(_ request: URLRequest) -> URLRequest
}
