//
//  APIClientTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 13/5/26.
//

import Foundation
import Testing
@testable import TypedNetwork

struct APIClientTests {

    struct User: Decodable, Equatable {
        let id: Int
        let name: String
    }

    enum APIError: Error {
        case server
    }

    struct GetUser: Endpoint {
        typealias Response = User
        typealias Failure = APIError

        let id: Int

        var path: String { "/users/\(id)" }
        var method: HTTPMethod { .get }

        func mapError(data: Data, response: HTTPURLResponse) -> APIError {
            .server
        }
    }

    @Test
    func mocked_endpoint_returns_expected_response() async throws {
        let mock = MockRegistry()
        await mock.register(GetUser(id: 1), response: User(id: 1, name: "Mocked"))

        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            mockRegistry: mock
        )

        let user = try await client.send(GetUser(id: 1))

        #expect(user == User(id: 1, name: "Mocked"))
    }

    @Test
    func endpoint_throws_typed_error() async throws {
        struct APIError: Codable, Error, Sendable, Equatable {
            let message: String
        }

        struct FailingEndpoint: Endpoint {
            typealias Response = String
            typealias Failure = APIError

            var path: String { "/fail" }
            var method: HTTPMethod { .get }

            func mapError(data: Data, response: HTTPURLResponse) -> APIError {
                try! JSONDecoder().decode(APIError.self, from: data)
            }
        }

        // mock session devuelve 400 con JSON de error
    }
}
