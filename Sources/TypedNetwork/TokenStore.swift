//
//  TokenStore.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Foundation

import Foundation

public actor TokenStore {

    private var token: String

    public init(token: String) {
        self.token = token
    }

    public func get() -> String {
        token
    }

    public func set(_ new: String) {
        token = new
    }
}
