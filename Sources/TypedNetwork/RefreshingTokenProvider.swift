//
//  RefreshingTokenProvider.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 21/5/26.
//

import Foundation

public actor RefreshingTokenProvider: TokenProvider {

    public typealias RefreshClosure = @Sendable () async throws -> AuthToken

    private let store: TokenStore
    private let refresh: RefreshClosure

    private var refreshTask: Task<AuthToken, Error>?

    public init(
        store: TokenStore,
        refresh: @escaping RefreshClosure
    ) {
        self.store = store
        self.refresh = refresh
    }

    public func validToken() async throws -> String {

        if let token = await store.get(),
           !token.isExpired,
           !token.expiresSoon() {

            return token.accessToken
        }

        let refreshed = try await refreshToken()

        return refreshed.accessToken
    }

    private func refreshToken(
        force: Bool = false
    ) async throws -> AuthToken {

        if !force,
           let refreshTask {
            return try await refreshTask.value
        }

        let task = Task {
            try await refresh()
        }

        refreshTask = task

        defer {
            refreshTask = nil
        }

        let token = try await task.value

        await store.set(token)

        return token
    }

    public func forceRefresh() async throws -> String {

        let token = try await refreshToken(force: true)

        return token.accessToken
    }
}
