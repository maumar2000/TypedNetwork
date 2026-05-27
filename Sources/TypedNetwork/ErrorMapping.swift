import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum NetworkError: Error {
    case transport(URLError)
    case decoding(Error)
    case endpoint(Error)
}
