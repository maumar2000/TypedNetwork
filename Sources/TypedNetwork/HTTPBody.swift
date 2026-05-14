//
//  HTTPBody.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Foundation

public enum HTTPBody: Sendable {
    case data(Data)
    case encodable(Encodable & Sendable)

    func encode() throws -> Data {
        switch self {
        case .data(let data):
            return data
        case .encodable(let value):
            return try JSONEncoder().encode(AnyEncodable(value))
        }
    }
}

struct AnyEncodable: Sendable {
    private let encodeFunc: @Sendable (Encoder) throws -> Void

    init<T: Encodable & Sendable>(_ value: T) {
        self.encodeFunc = { encoder in
            try value.encode(to: encoder)
        }
    }
}

extension AnyEncodable: Encodable {
    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
