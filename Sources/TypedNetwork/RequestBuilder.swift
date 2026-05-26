import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct RequestBuilder {

    let baseURL: URL
    let modifiers: [any RequestModifier]

    init(baseURL: URL, modifiers: [any RequestModifier] = []) {
        self.baseURL = baseURL
        self.modifiers = modifiers
    }

    func build<E: Endpoint>(from endpoint: E) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )!

        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        let url = components.url!

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        if let body = endpoint.body {
            request.httpBody = try body.encode()
        }

        if let timeout = endpoint.timeout {
            request.timeoutInterval = timeout.timeInterval
        }

        for modifier in modifiers {
            request = modifier.modify(request)
        }

        return request
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let seconds = TimeInterval(components.seconds)
        let attoseconds = TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
        return seconds + attoseconds
    }
}
