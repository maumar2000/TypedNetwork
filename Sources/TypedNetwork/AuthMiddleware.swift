//
//  AuthMiddleware.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Foundation

public struct AuthMiddleware: Middleware {

    private let tokenStore: TokenStore
    private let refresh: @Sendable () async throws -> String

    public init(
        tokenStore: TokenStore,
        refresh: @escaping @Sendable () async throws -> String
    ) {
        self.tokenStore = tokenStore
        self.refresh = refresh
    }

    public func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {

        var authorized = request
        let token = await tokenStore.get()
        authorized.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await next(authorized)

        if response.statusCode == 401 {
            let newToken = try await refresh()
            await tokenStore.set(newToken)

            var retry = request
            retry.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")

            return try await next(retry)
        }

        return (data, response)
    }
}
