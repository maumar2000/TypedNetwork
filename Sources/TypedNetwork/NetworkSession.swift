//
//  NetworkSession.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 18/5/26.
//

import Foundation

public protocol NetworkSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}
