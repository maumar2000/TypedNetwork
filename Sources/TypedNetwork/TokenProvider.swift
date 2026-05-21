//
//  TokenProvider.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 21/5/26.
//

import Foundation

public protocol TokenProvider: Sendable {

    func validToken() async throws -> String

    func forceRefresh() async throws -> String
}
