import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import TypedNetwork

struct NetworkErrorTests {

    private struct User: Decodable, Sendable, Equatable {
        let name: String
    }

    private enum APIError: Error, Sendable, Equatable {
        case unauthorized
    }

    private struct UserEndpoint: Endpoint {
        typealias Response = User
        typealias Failure = APIError

        var path: String { "/user" }
        var method: HTTPMethod { .get }

        func mapError(data: Data, response: HTTPURLResponse) -> APIError {
            .unauthorized
        }
    }

    @Test
    func api_client_wraps_endpoint_failure_in_network_error() async {
        let http = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = StubSession(data: Data(), response: http)
        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            session: session
        )

        do {
            _ = try await client.send(UserEndpoint())
            Issue.record("Expected NetworkError.endpoint")
        } catch let error as NetworkError {
            guard case .endpoint(let underlying) = error else {
                Issue.record("Expected endpoint case, got \(error)")
                return
            }
            #expect(underlying as? APIError == .unauthorized)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func api_client_wraps_transport_error_in_network_error() async {
        let session = FailingSession()
        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            session: session
        )

        do {
            _ = try await client.send(UserEndpoint())
            Issue.record("Expected NetworkError.transport")
        } catch let error as NetworkError {
            guard case .transport(let urlError) = error else {
                Issue.record("Expected transport case, got \(error)")
                return
            }
            #expect(urlError.code == .notConnectedToInternet)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func api_client_wraps_decoding_error_in_network_error() async throws {
        let json = #"not-json"#.data(using: .utf8)!
        let http = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = StubSession(data: json, response: http)
        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            session: session
        )

        do {
            _ = try await client.send(UserEndpoint())
            Issue.record("Expected NetworkError.decoding")
        } catch let error as NetworkError {
            guard case .decoding = error else {
                Issue.record("Expected decoding case, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private final class FailingSession: NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.notConnectedToInternet)
    }
}
