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

    struct Body: Encodable, Equatable {
        let name: String
    }

    @Test
    func encodable_body_is_encoded_to_json_data() throws {
        let body = HTTPBody.encodable(Body(name: "Mauri"))

        let data = try body.encode()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        #expect(json?["name"] == "Mauri")
    }

    @Test
    func data_body_returns_same_data() throws {
        let original = Data([0x01, 0x02, 0x03])
        let body = HTTPBody.data(original)

        let encoded = try body.encode()

        #expect(encoded == original)
    }
}
