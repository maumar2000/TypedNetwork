import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import TypedNetwork

struct MockMiddlewareTests {

    private struct Profile: Decodable, Sendable, Equatable {
        let name: String
    }

    private struct GetProfile: Endpoint {
        typealias Response = Profile
        typealias Failure = Never

        var path: String { "/profile" }
        var method: HTTPMethod { .get }
    }

    @Test
    func mock_middleware_short_circuits_transport() async throws {
        let json = #"{"name":"Mocked"}"#.data(using: .utf8)!
        let url = URL(string: "https://test.com/profile")!
        let http = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let mock = MockMiddleware { request in
            guard request.url?.path.hasSuffix("/profile") == true else {
                return nil
            }
            return (json, http)
        }

        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            middlewares: [mock]
        )

        let profile = try await client.send(GetProfile())
        #expect(profile == Profile(name: "Mocked"))
    }

    @Test
    func mock_middleware_falls_through_when_no_match() async throws {
        let json = #"{"name":"Real"}"#.data(using: .utf8)!
        let http = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = StubSession(data: json, response: http)

        let mock = MockMiddleware { _ in nil }

        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            session: session,
            middlewares: [mock]
        )

        let profile = try await client.send(GetProfile())
        #expect(profile.name == "Real")
    }
}
