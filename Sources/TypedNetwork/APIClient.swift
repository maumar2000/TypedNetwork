import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor APIClient {

    private let session: NetworkSession
    private let builder: RequestBuilder
    private let mockRegistry: MockRegistry?
    private let middlewares: [any Middleware]
    private let decoder: ResponseDecoder

    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        mockRegistry: MockRegistry? = nil,
        middlewares: [any Middleware] = [],
        requestModifiers: [any RequestModifier] = [],
        decoder: ResponseDecoder = JSONResponseDecoder(),
    ) {
        self.session = session
        self.builder = RequestBuilder(baseURL: baseURL, modifiers: requestModifiers)
        self.mockRegistry = mockRegistry
        self.middlewares = middlewares
        self.decoder = decoder
    }

    public func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        if let mock = await mockRegistry?.response(for: endpoint) as? E.Response {
            return mock
        }

        let request = try builder.build(from: endpoint)

        let chain = MiddlewareChain(middlewares)

        do {
            let (data, http) = try await chain.execute(
                request: request
            ) { request in
                do {
                    let (data, response) = try await self.session.data(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw NetworkError.transport(URLError(.badServerResponse))
                    }
                    return (data, http)
                } catch let error as NetworkError {
                    throw error
                } catch let error as URLError {
                    throw NetworkError.transport(error)
                }
            }

            if (200..<300).contains(http.statusCode) {
                do {
                    return try decoder.decode(
                        data: data,
                        response: http,
                        for: endpoint
                    )
                } catch {
                    throw NetworkError.decoding(error)
                }
            } else {
                throw NetworkError.endpoint(
                    endpoint.mapError(data: data, response: http)
                )
            }
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            throw NetworkError.transport(error)
        }
    }
}
