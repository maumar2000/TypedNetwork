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

    private struct MockTokenProvider: TokenProvider {

        let token: String
        let refreshedToken: String?

        init(
            token: String,
            refreshedToken: String? = nil
        ) {
            self.token = token
            self.refreshedToken = refreshedToken
        }

        func validToken() async throws -> String {
            token
        }

        func forceRefresh() async throws -> String {
            refreshedToken ?? token
        }
    }

    @Test
    func auth_middleware_adds_authorization_header() async throws {

        let provider = MockTokenProvider(
            token: "valid-token"
        )

        let middleware = AuthMiddleware(
            tokenProvider: provider
        )

        let chain = MiddlewareChain([middleware])

        let request = URLRequest(
            url: URL(string: "https://test.com")!
        )

        let (_, response) = try await chain.execute(
            request: request
        ) { req in

            #expect(
                req.value(forHTTPHeaderField: "Authorization")
                == "Bearer valid-token"
            )

            return (
                Data(),
                HTTPURLResponse(
                    url: req.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        }

        #expect(response.statusCode == 200)
    }

    @Test
    func auth_middleware_refreshes_token_after_401() async throws {

        let provider = MockTokenProvider(
            token: "expired-token",
            refreshedToken: "new-token"
        )

        let middleware = AuthMiddleware(
            tokenProvider: provider
        )

        let chain = MiddlewareChain([middleware])

        let request = URLRequest(
            url: URL(string: "https://test.com")!
        )

        let counter = Counter()

        let (_, response) = try await chain.execute(
            request: request
        ) { req in

            await counter.increment()

            let current = await counter.get()

            if current == 1 {

                #expect(
                    req.value(forHTTPHeaderField: "Authorization")
                    == "Bearer expired-token"
                )

                return (
                    Data(),
                    HTTPURLResponse(
                        url: req.url!,
                        statusCode: 401,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                )
            }

            #expect(
                req.value(forHTTPHeaderField: "Authorization")
                == "Bearer new-token"
            )

            return (
                Data(),
                HTTPURLResponse(
                    url: req.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        }

        #expect(await counter.get() == 2)
        #expect(response.statusCode == 200)
    }
}
