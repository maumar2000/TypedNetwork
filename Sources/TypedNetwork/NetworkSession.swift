//
//  NetworkSession.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 18/5/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol NetworkSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}
