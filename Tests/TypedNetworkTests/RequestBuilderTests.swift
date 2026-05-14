//
//  RequestBuilderTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Testing
@testable import TypedNetwork
import Foundation

struct RequestBuilderTests {

    @Test
    func builder_creates_correct_request() throws {
        struct TestEndpoint: Endpoint {
            typealias Response = String

            var path: String { "users/10" }
            var method: HTTPMethod { .get }
        }

        let baseURL = URL(string: "https://api.test.com")!
        let builder = RequestBuilder(baseURL: baseURL)

        let request = try builder.build(from: TestEndpoint())

        #expect(request.url?.absoluteString == "https://api.test.com/users/10")
        #expect(request.httpMethod == "GET")
    }
}
