import Foundation
import Testing
@testable import TypedNetwork

private actor HeaderCapture {
    var userAgent: String?

    func capture(from request: URLRequest) {
        userAgent = request.value(forHTTPHeaderField: "User-Agent")
    }
}

struct RequestModifierTests {

    private struct ModifierEndpoint: Endpoint {
        typealias Response = String
        typealias Failure = Never

        var path: String
        var method: HTTPMethod
        var timeout: Duration?
    }

    private struct UserAgentModifier: RequestModifier {
        func modify(_ request: URLRequest) -> URLRequest {
            var modified = request
            modified.setValue("TypedNetworkTests/1.0", forHTTPHeaderField: "User-Agent")
            return modified
        }
    }

    @Test
    func request_builder_applies_modifiers() throws {
        let builder = RequestBuilder(
            baseURL: URL(string: "https://api.test.com")!,
            modifiers: [UserAgentModifier()]
        )

        let request = try builder.build(
            from: ModifierEndpoint(path: "users", method: .get)
        )

        #expect(request.value(forHTTPHeaderField: "User-Agent") == "TypedNetworkTests/1.0")
    }

    @Test
    func request_builder_applies_endpoint_timeout() throws {
        let builder = RequestBuilder(baseURL: URL(string: "https://api.test.com")!)

        let request = try builder.build(
            from: ModifierEndpoint(
                path: "users",
                method: .get,
                timeout: .seconds(42)
            )
        )

        #expect(request.timeoutInterval == 42)
    }

    @Test
    func api_client_applies_request_modifiers() async throws {
        let json = #"{"name":"ok"}"#.data(using: .utf8)!

        struct NameResponse: Decodable, Sendable, Equatable {
            let name: String
        }

        struct NameEndpoint: Endpoint {
            typealias Response = NameResponse
            typealias Failure = Never

            var path: String { "/name" }
            var method: HTTPMethod { .get }
        }

        let capture = HeaderCapture()

        let http = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = CapturingSession(capture: capture, data: json, response: http)

        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            session: session,
            requestModifiers: [UserAgentModifier()]
        )

        _ = try await client.send(NameEndpoint())
        #expect(await capture.userAgent == "TypedNetworkTests/1.0")
    }
}

private final class CapturingSession: NetworkSession {
    let capture: HeaderCapture
    let data: Data
    let response: URLResponse

    init(capture: HeaderCapture, data: Data, response: URLResponse) {
        self.capture = capture
        self.data = data
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        await capture.capture(from: request)
        return (data, response)
    }
}
