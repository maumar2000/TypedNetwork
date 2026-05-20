//
//  ResponseDecoder.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 18/5/26.
//

import Foundation

public protocol ResponseDecoder: Sendable {
    func decode<E: Endpoint>(
        data: Data,
        response: HTTPURLResponse,
        for endpoint: E
    ) throws -> E.Response
}

public struct JSONResponseDecoder: ResponseDecoder {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func decode<E: Endpoint>(
        data: Data,
        response: HTTPURLResponse,
        for endpoint: E
    ) throws -> E.Response {
        try decoder.decode(E.Response.self, from: data)
    }
}
