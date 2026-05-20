//
//  RetryMiddlewareTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 20/5/26.
//

import Foundation
import Testing
@testable import TypedNetwork

struct RetryMiddlewareTests {

    actor CallCounter {
        private(set) var value = 0
        func increment() { value += 1 }
    }

    private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    @Test
    func retries_when_policy_allows() async throws {
        let policy = RetryPolicy(
            maxRetries: 2,
            delay: .seconds(0),
            shouldRetry: { $0.statusCode == 500 }
        )

        let middleware = RetryMiddleware(policy: policy)
        let counter = CallCounter()

        let result = try await middleware.intercept(
            URLRequest(url: URL(string: "https://test.com")!)
        ) { _ in
            await counter.increment()

            let current = await counter.value
            if current < 3 {
                return (Data(), self.makeHTTPResponse(statusCode: 500))
            } else {
                return (Data("ok".utf8), self.makeHTTPResponse(statusCode: 200))
            }
        }

        #expect(await counter.value == 3)
        #expect(result.1.statusCode == 200)
    }

    @Test
    func does_not_retry_when_policy_blocks() async throws {
        let policy = RetryPolicy(
            maxRetries: 3,
            delay: .seconds(0),
            shouldRetry: { _ in false }
        )

        let middleware = RetryMiddleware(policy: policy)
        let counter = CallCounter()

        let result = try await middleware.intercept(
            URLRequest(url: URL(string: "https://test.com")!)
        ) { _ in
            await counter.increment()
            return (Data(), self.makeHTTPResponse(statusCode: 500))
        }

        #expect(await counter.value == 1)
        #expect(result.1.statusCode == 500)
    }

    @Test
    func stops_retrying_after_max_retries() async throws {
        let policy = RetryPolicy(
            maxRetries: 1,
            delay: .seconds(0),
            shouldRetry: { $0.statusCode == 500 }
        )

        let middleware = RetryMiddleware(policy: policy)
        let counter = CallCounter()

        let result = try await middleware.intercept(
            URLRequest(url: URL(string: "https://test.com")!)
        ) { _ in
            await counter.increment()
            return (Data(), self.makeHTTPResponse(statusCode: 500))
        }

        #expect(await counter.value == 2)
        #expect(result.1.statusCode == 500)
    }
}
