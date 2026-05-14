import Foundation

actor APIClient {

    private let session: URLSession
    private let builder: RequestBuilder
    private let mockRegistry: MockRegistry?

    init(
        baseURL: URL,
        session: URLSession = .shared,
        mockRegistry: MockRegistry? = nil
    ) {
        self.session = session
        self.builder = RequestBuilder(baseURL: baseURL)
        self.mockRegistry = mockRegistry
    }

    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        if let mock = await mockRegistry?.response(for: endpoint) as? E.Response {
            return mock
        }

        let request = try builder.build(from: endpoint)

        let (data, urlResponse) = try await session.data(for: request)

        guard let http = urlResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200..<300).contains(http.statusCode) {
            return try JSONDecoder().decode(E.Response.self, from: data)
        } else {
            throw endpoint.mapError(data: data, response: http)
        }
    }
}
