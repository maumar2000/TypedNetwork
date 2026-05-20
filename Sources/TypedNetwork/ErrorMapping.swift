import Foundation

public enum NetworkError: Error {
    case transport(URLError)
    case decoding(Error)
    case endpoint(Error)
}
