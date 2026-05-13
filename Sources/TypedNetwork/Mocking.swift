import Foundation

public final class MockRegistry {
    private var storage: [String: Any] = [:]

    public init() {}

    public func register<E: Endpoint>(_ endpoint: E.Type, response: E.Response) {
        storage[String(describing: endpoint)] = response
    }

    func response<E: Endpoint>(for endpoint: E.Type) -> E.Response? {
        storage[String(describing: endpoint)] as? E.Response
    }
}
