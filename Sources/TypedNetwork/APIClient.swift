import Foundation

public final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let middlewareChain: MiddlewareChain
    private let mockRegistry: MockRegistry?

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        middlewares: [Middleware] = [],
        mockRegistry: MockRegistry? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.middlewareChain = MiddlewareChain(middlewares)
        self.mockRegistry = mockRegistry
    }

    public func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        // Mock first
        if let mock = mockRegistry?.response(for: E.self) {
            return mock
        }

        let request = try endpoint.makeRequest(baseURL: baseURL)
        let finalRequest = try await middlewareChain.run(request)

        do {
            let (data, response) = try await session.data(for: finalRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            if 200..<300 ~= httpResponse.statusCode {
                do {
                    return try JSONDecoder().decode(E.Response.self, from: data)
                } catch {
                    throw NetworkError.decoding(error)
                }
            } else {
                throw endpoint.mapError(data: data, response: httpResponse)
            }

        } catch {
            throw NetworkError.transport(error)
        }
    }
}
