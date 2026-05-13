import Foundation

public enum RequestBuilder {
    public static func jsonBody<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }
}
