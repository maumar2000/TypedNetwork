//
//  RefreshingTokenProviderTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 21/5/26.
//

import Foundation
import Testing
@testable import TypedNetwork

struct RefreshingTokenProviderTests {

    actor Counter {
        private var value = 0

        func increment() {
            value += 1
        }

        func get() -> Int {
            value
        }
    }

    @Test
    func returns_existing_valid_token_without_refresh() async throws {

        let token = AuthToken(
            accessToken: "valid-token",
            expiration: Date().addingTimeInterval(3600)
        )

        let store = TokenStore(token: token)

        let counter = Counter()

        let provider = RefreshingTokenProvider(
            store: store
        ) {
            await counter.increment()

            return AuthToken(
                accessToken: "new-token",
                expiration: Date().addingTimeInterval(3600)
            )
        }

        let result = try await provider.validToken()

        #expect(result == "valid-token")
        #expect(await counter.get() == 0)
    }

    @Test
    func refreshes_expired_token() async throws {

        let expired = AuthToken(
            accessToken: "expired",
            expiration: Date().addingTimeInterval(-3600)
        )

        let store = TokenStore(token: expired)

        let counter = Counter()

        let provider = RefreshingTokenProvider(
            store: store
        ) {

            await counter.increment()

            return AuthToken(
                accessToken: "new-token",
                expiration: Date().addingTimeInterval(3600)
            )
        }

        let result = try await provider.validToken()

        #expect(result == "new-token")
        #expect(await counter.get() == 1)

        let stored = await store.get()

        #expect(stored?.accessToken == "new-token")
    }

    @Test
    func concurrent_requests_trigger_only_one_refresh() async throws {

        let expired = AuthToken(
            accessToken: "expired",
            expiration: Date().addingTimeInterval(-3600)
        )

        let store = TokenStore(token: expired)

        let counter = Counter()

        let provider = RefreshingTokenProvider(
            store: store
        ) {

            await counter.increment()

            try await Task.sleep(for: .milliseconds(100))

            return AuthToken(
                accessToken: "shared-token",
                expiration: Date().addingTimeInterval(3600)
            )
        }

        async let first = provider.validToken()
        async let second = provider.validToken()
        async let third = provider.validToken()

        let results = try await [
            first,
            second,
            third
        ]

        #expect(results[0] == "shared-token")
        #expect(results[1] == "shared-token")
        #expect(results[2] == "shared-token")

        #expect(await counter.get() == 1)
    }

    @Test
    func refresh_failure_is_propagated() async {

        struct DummyError: Error {}

        let expired = AuthToken(
            accessToken: "expired",
            expiration: Date().addingTimeInterval(-3600)
        )

        let store = TokenStore(token: expired)

        let provider = RefreshingTokenProvider(
            store: store
        ) {
            throw DummyError()
        }

        await #expect(throws: DummyError.self) {
            _ = try await provider.validToken()
        }
    }

    @Test
    func force_refresh_always_refreshes_token() async throws {

        let valid = AuthToken(
            accessToken: "valid-token",
            expiration: Date().addingTimeInterval(3600)
        )

        let store = TokenStore(token: valid)

        let counter = Counter()

        let provider = RefreshingTokenProvider(
            store: store
        ) {

            await counter.increment()

            return AuthToken(
                accessToken: "refreshed-token",
                expiration: Date().addingTimeInterval(3600)
            )
        }

        let token = try await provider.forceRefresh()

        #expect(token == "refreshed-token")

        #expect(await counter.get() == 1)

        let stored = await store.get()

        #expect(stored?.accessToken == "refreshed-token")
    }
}
