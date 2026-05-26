import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import TypedNetwork

struct LoggingMiddlewareTests {

    final class LogRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var lines: [String] = []

        func append(_ line: String) {
            lock.lock()
            lines.append(line)
            lock.unlock()
        }

        func all() -> [String] {
            lock.lock()
            defer { lock.unlock() }
            return lines
        }
    }

    @Test
    func logs_request_and_response_details() async throws {
        let recorder = LogRecorder()

        let middleware = LoggingMiddleware { line in
            recorder.append(line)
        }

        var request = URLRequest(url: URL(string: "https://api.test.com/users")!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let chain = MiddlewareChain([middleware])

        _ = try await chain.execute(request: request) { req in
            #expect(req.httpMethod == "GET")
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

        let lines = recorder.all()
        #expect(lines.count == 3)
        #expect(lines[0].contains("→ GET"))
        #expect(lines[0].contains("https://api.test.com/users"))
        #expect(lines[1].contains("headers:"))
        #expect(lines[1].contains("Accept"))
        #expect(lines[2].contains("← 200"))
    }
}
