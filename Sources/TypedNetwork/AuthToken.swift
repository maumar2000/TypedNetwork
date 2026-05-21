//
//  AuthToken.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 21/5/26.
//

import Foundation

public struct AuthToken: Sendable {

    public let accessToken: String
    public let expiration: Date

    public init(
        accessToken: String,
        expiration: Date
    ) {
        self.accessToken = accessToken
        self.expiration = expiration
    }

    public var isExpired: Bool {
        expiration <= Date()
    }

    public func expiresSoon(
        threshold: TimeInterval = 60
    ) -> Bool {
        expiration.timeIntervalSinceNow <= threshold
    }
}
