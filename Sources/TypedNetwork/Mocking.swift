import Foundation

public actor MockRegistry {
    private var storage: [String: Any] = [:]

    public init() {}

    public func register<E: Endpoint>(_ endpoint: E, response: E.Response) {
        storage[key(for: endpoint)] = response
    }

    func response<E: Endpoint>(for endpoint: E) -> E.Response? {
        storage[key(for: endpoint)] as? E.Response
    }

    private func key<E: Endpoint>(for endpoint: E) -> String {
        String(describing: E.self) + endpoint.path
    }
}
