//
//  AuthTokenTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 21/5/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import TypedNetwork

struct AuthTokenTests {

    @Test
    func token_is_not_expired_when_expiration_is_in_future() {

        let token = AuthToken(
            accessToken: "abc",
            expiration: Date().addingTimeInterval(3600)
        )

        #expect(token.isExpired == false)
    }

    @Test
    func token_is_expired_when_expiration_is_in_past() {

        let token = AuthToken(
            accessToken: "abc",
            expiration: Date().addingTimeInterval(-3600)
        )

        #expect(token.isExpired == true)
    }

    @Test
    func token_expires_soon_when_inside_threshold() {

        let token = AuthToken(
            accessToken: "abc",
            expiration: Date().addingTimeInterval(30)
        )

        #expect(
            token.expiresSoon(threshold: 60) == true
        )
    }

    @Test
    func token_does_not_expire_soon_when_outside_threshold() {

        let token = AuthToken(
            accessToken: "abc",
            expiration: Date().addingTimeInterval(300)
        )

        #expect(
            token.expiresSoon(threshold: 60) == false
        )
    }
}
