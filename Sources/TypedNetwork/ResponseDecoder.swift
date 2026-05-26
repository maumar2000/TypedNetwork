//
//  ResponseDecoder.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 18/5/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
        if E.Response.self == EmptyResponse.self {
            return EmptyResponse() as! E.Response
        }

        return try decoder.decode(E.Response.self, from: data)
    }
}
