//
//  HTTPBody.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Foundation

public struct HTTPBody: Sendable {
    private let encoder: @Sendable () throws -> Data
    public let contentType: String

    private init(
        contentType: String,
        encoder: @escaping @Sendable () throws -> Data
    ) {
        self.contentType = contentType
        self.encoder = encoder
    }

    public func encode() throws -> Data {
        try encoder()
    }
}

public extension HTTPBody {
    static func data(
        _ data: Data,
        contentType: String
    ) -> HTTPBody {
        HTTPBody(
            contentType: contentType,
            encoder: { data }
        )
    }
}

public extension HTTPBody {
    static func json<T: Encodable & Sendable>(
        _ value: T,
        encoder: JSONEncoder = JSONEncoder()
    ) -> HTTPBody {
        HTTPBody(
            contentType: "application/json",
            encoder: {
                try encoder.encode(value)
            }
        )
    }
}
