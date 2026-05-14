import Foundation

struct RequestBuilder {

    let baseURL: URL

    func build<E: Endpoint>(from endpoint: E) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        if let body = endpoint.body {
            request.httpBody = try body.encode()
        }

        return request
    }
}
