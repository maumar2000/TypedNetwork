//
//  HTTPBodyTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Foundation
import Testing
@testable import TypedNetwork

struct HTTPBodyTests {

    @Test
    func json_body_encodes_correctly_and_sets_content_type() throws {
        struct Body: Codable, Sendable, Equatable {
            let name: String
        }

        let body = HTTPBody.json(Body(name: "Mauri"))

        let data = try body.encode()
        let decoded = try JSONDecoder().decode(Body.self, from: data)

        #expect(decoded == Body(name: "Mauri"))
        #expect(body.contentType == "application/json")
    }

    @Test
    func data_body_returns_same_data_and_content_type() throws {
        let original = Data([0x01, 0x02, 0x03])

        let body = HTTPBody.data(original, contentType: "application/octet-stream")

        let encoded = try body.encode()

        #expect(encoded == original)
        #expect(body.contentType == "application/octet-stream")
    }
}
