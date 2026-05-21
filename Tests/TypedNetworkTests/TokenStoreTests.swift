//
//  TokenStoreTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 21/5/26.
//

import Foundation
import Testing
@testable import TypedNetwork

struct TokenStoreTests {

    @Test
    func store_returns_nil_when_empty() async {

        let store = TokenStore()

        let token = await store.get()

        #expect(token == nil)
    }

    @Test
    func store_returns_saved_token() async {

        let expected = AuthToken(
            accessToken: "abc",
            expiration: Date().addingTimeInterval(3600)
        )

        let store = TokenStore(
            token: expected
        )

        let token = await store.get()

        #expect(token?.accessToken == "abc")
    }

    @Test
    func store_updates_token() async {

        let store = TokenStore()

        let token = AuthToken(
            accessToken: "new-token",
            expiration: Date().addingTimeInterval(3600)
        )

        await store.set(token)

        let stored = await store.get()

        #expect(stored?.accessToken == "new-token")
    }

    @Test
    func store_clears_token() async {

        let token = AuthToken(
            accessToken: "abc",
            expiration: Date().addingTimeInterval(3600)
        )

        let store = TokenStore(
            token: token
        )

        await store.clear()

        let stored = await store.get()

        #expect(stored == nil)
    }
}
