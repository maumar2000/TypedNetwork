//
//  APIClientDecoderTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 18/5/26.
//

import Foundation
import Testing
@testable import TypedNetwork

private struct DummyResponse: Decodable, Sendable, Equatable {
    let value: String
}

private struct DummyEndpoint: Endpoint {
    typealias Response = DummyResponse
    typealias Failure = Never

    var path: String { "/dummy" }
    var method: HTTPMethod { .get }
}

private enum DummyError: Error, Sendable, Equatable {
    case badRequest
}

private struct DummyFailingEndpoint: Endpoint {
    typealias Response = DummyResponse
    typealias Failure = DummyError

    var path: String { "/fail" }
    var method: HTTPMethod { .get }

    func mapError(data: Data, response: HTTPURLResponse) -> DummyError {
        .badRequest
    }
}

private struct StubDecoder: ResponseDecoder {
    let expected: DummyResponse

    func decode<E>(
        data: Data,
        response: HTTPURLResponse,
        for endpoint: E
    ) throws -> E.Response where E : Endpoint {
        // Ignora completamente el JSON
        return expected as! E.Response
    }
}

@Test
func api_client_uses_injected_decoder_instead_of_jsondecoder() async throws {
    let expected = DummyResponse(value: "from stub")

    let decoder = StubDecoder(expected: expected)

    let mock = MockRegistry()
    await mock.register(DummyEndpoint(), response: expected)

    let client = APIClient(
        baseURL: URL(string: "https://test.com")!,
        mockRegistry: mock, decoder: decoder
    )

    let result = try await client.send(DummyEndpoint())

    #expect(result == expected)
}

final class StubSession: NetworkSession {
    let data: Data
    let response: URLResponse

    init(data: Data, response: URLResponse) {
        self.data = data
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return (data, response)
    }
}

@Test
func send_decodes_response_when_status_200() async throws {
    let json = #"{"value":"ok"}"#.data(using: .utf8)!

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

    let result = try await client.send(DummyEndpoint())

    #expect(result.value == "ok")
}

@Test
func send_throws_typed_error_when_status_not_2xx() async {
    let data = Data()

    let http = HTTPURLResponse(
        url: URL(string: "https://test.com")!,
        statusCode: 400,
        httpVersion: nil,
        headerFields: nil
    )!

    let session = StubSession(data: data, response: http)

    let client = APIClient(
        baseURL: URL(string: "https://test.com")!,
        session: session
    )

    await #expect(throws: DummyError.self) {
        try await client.send(DummyFailingEndpoint())
    }
}

@Test
func send_throws_when_response_is_not_http() async {
    let response = URLResponse()

    let session = StubSession(data: Data(), response: response)

    let client = APIClient(
        baseURL: URL(string: "https://test.com")!,
        session: session
    )

    await #expect(throws: URLError.self) {
        try await client.send(DummyEndpoint())
    }
}
