//
//  MiddlewareChainTests.swift
//  TypedNetwork
//
//  Created by Mauricio Martinez on 14/5/26.
//

import Testing
@testable import TypedNetwork
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct MiddlewareChainTests {

    struct OrderMiddleware: Middleware {
        let id: Int
        let recorder: Recorder

        func intercept(
            _ request: URLRequest,
            next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
        ) async throws -> (Data, HTTPURLResponse) {
            await recorder.record(id)
            return try await next(request)
        }
    }

    actor Recorder {
        var values: [Int] = []

        func record(_ value: Int) {
            values.append(value)
        }

        func all() -> [Int] { values }
    }

    @Test
    func middlewares_run_in_order() async throws {
        let recorder = Recorder()

        let chain = MiddlewareChain([
            OrderMiddleware(id: 1, recorder: recorder),
            OrderMiddleware(id: 2, recorder: recorder),
            OrderMiddleware(id: 3, recorder: recorder),
        ])

        let request = URLRequest(url: URL(string: "https://test.com")!)

        _ = try await chain.execute(request: request) { _ in
            (
                Data(),
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        }

        let result = await recorder.all()
        #expect(result == [1, 2, 3])
    }

    @Test
    func middleware_can_modify_request() async throws {
        struct HeaderMiddleware: Middleware {
            func intercept(
                _ request: URLRequest,
                next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
            ) async throws -> (Data, HTTPURLResponse) {

                var modified = request
                modified.setValue("123", forHTTPHeaderField: "X-Test")

                return try await next(modified)
            }
        }

        let chain = MiddlewareChain([HeaderMiddleware()])

        let request = URLRequest(url: URL(string: "https://test.com")!)

        _ = try await chain.execute(request: request) { req in
            #expect(req.value(forHTTPHeaderField: "X-Test") == "123")
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
    }

    @Test
    func middleware_can_inspect_response() async throws {
        struct ResponseCheckMiddleware: Middleware {
            let recorder: Recorder

            func intercept(
                _ request: URLRequest,
                next: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
            ) async throws -> (Data, HTTPURLResponse) {

                let result = try await next(request)
                await recorder.record(result.1.statusCode)
                return result
            }
        }

        let recorder = Recorder()

        let chain = MiddlewareChain([
            ResponseCheckMiddleware(recorder: recorder)
        ])

        let request = URLRequest(url: URL(string: "https://test.com")!)

        _ = try await chain.execute(request: request) { _ in
            (
                Data(),
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        }

        let values = await recorder.all()
        #expect(values == [201])
    }

}
