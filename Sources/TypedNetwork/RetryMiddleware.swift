//
//  RetryMiddleware.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 20/5/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct RetryMiddleware: Middleware {

    private let maxRetries: Int
    private let delay: Duration
    private let shouldRetry: @Sendable (HTTPURLResponse) -> Bool

    public init(policy: RetryPolicy) {
        self.maxRetries = policy.maxRetries
        self.delay = policy.delay
        self.shouldRetry = policy.shouldRetry
    }

    public func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {

        var attempt = 0

        while true {
            let result = try await next(request)

            if !shouldRetry(result.1) {
                return result
            }

            guard attempt < maxRetries else {
                return result
            }

            attempt += 1
            try await Task.sleep(for: delay)
        }
    }
}

