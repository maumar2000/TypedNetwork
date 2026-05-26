import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct EmptyResponse: Decodable, Sendable, Equatable {}
