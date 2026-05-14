//
//  AuthMiddlewareTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//


import Foundation
import Testing
@testable import TypedNetwork

struct AuthMiddlewareTests {

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
    func auth_middleware_refreshes_token_on_401() async throws {
        let store = TokenStore(token: "old")
        let counter = Counter()

        let middleware = AuthMiddleware(
            tokenStore: store,
            refresh: {
                "new"
            }
        )

        let chain = MiddlewareChain([middleware])

        let request = URLRequest(url: URL(string: "https://test.com")!)

        _ = try await chain.execute(request: request) { req in
            await counter.increment()
            let current = await counter.get()

            if current == 1 {
                #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer old")
                return (
                    Data(),
                    HTTPURLResponse(url: req.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                )
            } else {
                #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer new")
                return (
                    Data(),
                    HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }
        }

        #expect(await counter.get() == 2)
    }

}
