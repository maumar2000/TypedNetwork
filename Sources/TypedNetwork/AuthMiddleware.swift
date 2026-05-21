//
//  AuthMiddleware.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Foundation

public struct AuthMiddleware: Middleware {

    private let tokenProvider: any TokenProvider

    public init(
        tokenProvider: any TokenProvider
    ) {
        self.tokenProvider = tokenProvider
    }

    public func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {

        let token = try await tokenProvider.validToken()

        var authorized = request

        authorized.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )

        let (data, response) = try await next(authorized)

        // Edge case:
        // invalid token or revoken suddenly
        if response.statusCode == 401 {

            let refreshed = try await tokenProvider.forceRefresh()

            var retry = request

            retry.setValue(
                "Bearer \(refreshed)",
                forHTTPHeaderField: "Authorization"
            )

            return try await next(retry)
        }

        return (data, response)
    }
}
