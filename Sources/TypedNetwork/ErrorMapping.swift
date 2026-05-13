import Foundation

public enum NetworkError: Error {
    case invalidResponse
    case decoding(Error)
    case transport(Error)
}
