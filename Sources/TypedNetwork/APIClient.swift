import Foundation

actor APIClient {

    private let session: URLSession
    private let builder: RequestBuilder
    private let mockRegistry: MockRegistry?
    private let middlewares: [any Middleware]

    init(
        baseURL: URL,
        session: URLSession = .shared,
        mockRegistry: MockRegistry? = nil,
        middlewares: [any Middleware] = []
    ) {
        self.session = session
        self.builder = RequestBuilder(baseURL: baseURL)
        self.mockRegistry = mockRegistry
        self.middlewares = middlewares
    }

    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        if let mock = await mockRegistry?.response(for: endpoint) as? E.Response {
            return mock
        }

        let request = try builder.build(from: endpoint)

        let chain = MiddlewareChain(middlewares)

        let (data, http) = try await chain.execute(
            request: request
        ) { request in
            let (data, response) = try await self.session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            return (data, http)
        }

        if (200..<300).contains(http.statusCode) {
            return try JSONDecoder().decode(E.Response.self, from: data)
        } else {
            throw endpoint.mapError(data: data, response: http)
        }
    }
}
