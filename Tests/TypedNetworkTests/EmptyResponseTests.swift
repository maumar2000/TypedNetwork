import Foundation
import Testing
@testable import TypedNetwork

struct EmptyResponseTests {

    private struct DeleteResource: Endpoint {
        typealias Response = EmptyResponse
        typealias Failure = Never

        var path: String { "/resource/1" }
        var method: HTTPMethod { .delete }
    }

    @Test
    func json_decoder_returns_empty_response_without_body() async throws {
        let decoder = JSONResponseDecoder()
        let http = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = try decoder.decode(
            data: Data(),
            response: http,
            for: DeleteResource()
        )

        #expect(result == EmptyResponse())
    }

    @Test
    func api_client_decodes_204_as_empty_response() async throws {
        let http = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = StubSession(data: Data(), response: http)
        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            session: session
        )

        let result = try await client.send(DeleteResource())
        #expect(result == EmptyResponse())
    }
}
