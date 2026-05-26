import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol RequestModifier: Sendable {
    func modify(_ request: URLRequest) -> URLRequest
}
