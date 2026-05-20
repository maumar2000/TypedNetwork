//
//  RetryPolicy.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 20/5/26.
//

import Foundation

public struct RetryPolicy: Sendable {
    public let maxRetries: Int
    public let delay: Duration
    public let shouldRetry: @Sendable (HTTPURLResponse) -> Bool

    public init(
        maxRetries: Int,
        delay: Duration = .seconds(1),
        shouldRetry: @escaping @Sendable (HTTPURLResponse) -> Bool
    ) {
        self.maxRetries = maxRetries
        self.delay = delay
        self.shouldRetry = shouldRetry
    }
}
