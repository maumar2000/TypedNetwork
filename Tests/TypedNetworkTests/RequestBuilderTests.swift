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

    private struct BuilderEndpoint: Endpoint {
        typealias Response = String
        typealias Failure = Never

        var path: String
        var method: HTTPMethod
        var headers: [String : String] = [:]
        var queryItems: [URLQueryItem] = []
        var body: HTTPBody? = nil
    }

    @Test
    func builder_creates_correct_url_with_path() throws {
        let builder = RequestBuilder(baseURL: URL(string: "https://api.test.com")!)

        let endpoint = BuilderEndpoint(
            path: "users",
            method: .get
        )

        let request = try builder.build(from: endpoint)

        #expect(request.url?.absoluteString == "https://api.test.com/users")
    }

    @Test
    func builder_adds_query_items() throws {
        let builder = RequestBuilder(baseURL: URL(string: "https://api.test.com")!)

        let endpoint = BuilderEndpoint(
            path: "search",
            method: .get,
            queryItems: [URLQueryItem(name: "q", value: "swift")]
        )

        let request = try builder.build(from: endpoint)

        #expect(request.url?.absoluteString.contains("q=swift") == true)
    }

    @Test
    func builder_sets_headers() throws {
        let builder = RequestBuilder(baseURL: URL(string: "https://api.test.com")!)

        let endpoint = BuilderEndpoint(
            path: "users",
            method: .get,
            headers: ["Authorization": "Bearer 123"]
        )

        let request = try builder.build(from: endpoint)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer 123")
    }

    @Test
    func builder_sets_http_method() throws {
        let builder = RequestBuilder(baseURL: URL(string: "https://api.test.com")!)

        let endpoint = BuilderEndpoint(
            path: "users",
            method: .post
        )

        let request = try builder.build(from: endpoint)

        #expect(request.httpMethod == "POST")
    }

    private struct Body: Encodable, Sendable {
        let name: String
    }

    @Test
    func builder_encodes_body() throws {
        let builder = RequestBuilder(baseURL: URL(string: "https://api.test.com")!)

        let endpoint = BuilderEndpoint(
            path: "users",
            method: .post,
            body: .json(Body(name: "Mauri"))
        )

        let request = try builder.build(from: endpoint)

        let json = try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: String]

        #expect(json?["name"] == "Mauri")
    }
}
