//
//  TokenStore.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Foundation

public actor TokenStore {

    private var token: AuthToken?

    public init(token: AuthToken? = nil) {
        self.token = token
    }

    public func get() -> AuthToken? {
        token
    }

    public func set(_ new: AuthToken) {
        token = new
    }

    public func clear() {
        token = nil
    }
}
