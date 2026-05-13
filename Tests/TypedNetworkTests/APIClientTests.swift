//
//  APIClientTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 13/5/26.
//

import XCTest
@testable import TypedNetwork

final class APIClientTests: XCTestCase {

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

    func test_mocked_endpoint_returns_expected_response() async throws {
        let mock = MockRegistry()
        mock.register(GetUser.self, response: User(id: 1, name: "Mocked"))

        let client = APIClient(
            baseURL: URL(string: "https://test.com")!,
            mockRegistry: mock
        )

        let user = try await client.send(GetUser(id: 1))

        XCTAssertEqual(user, User(id: 1, name: "Mocked"))
    }
}
