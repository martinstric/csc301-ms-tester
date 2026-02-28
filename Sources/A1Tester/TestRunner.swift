import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

class TestRunner {
    let serviceConfig: ServiceConfig
    let testBasePath: String
    let session: URLSession

    init(serviceConfig: ServiceConfig, testBasePath: String) {
        self.serviceConfig = serviceConfig
        self.testBasePath = testBasePath

        // Configure URLSession with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: config)
    }

    func loadTestSuite(for serviceName: String) throws -> TestSuite {
        let name = serviceName.capitalized
        let suitePath = "\(testBasePath)/\(serviceName.lowercased()).json"

        return try TestSuite(name: name, path: suitePath)
    }

    func runAllTests(_ suite: TestSuite) async -> TestResults {
        var results = TestResults()

        print("\n\u{001B}[33mRunning \(suite.name) tests...\u{001B}[0m")
        print("Loaded \(suite.testCases.count) test cases\n")

        for testCase in suite.testCases {
            let result = await runTest(testCase)
            results.add(result)
            printTestResult(result)
        }

        return results
    }

    private func runTest(_ testCase: TestCase) async -> TestResult {
        let startTime = Date()

        do {
            // Build URL
            let url = buildURL(for: testCase)

            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = testCase.method.rawValue

            // Add body when present
            if let body = testCase.body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            }

            // Execute request
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                return TestResult(
                    testCase: testCase,
                    passed: false,
                    error: "Invalid response type",
                    duration: duration
                )
            }

            // Parse response body
            let responseBody: [String: Any]
            if data.isEmpty {
                responseBody = [:]
            } else {
                if let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    responseBody = parsed
                } else {
                    responseBody = [:]
                }
            }

            // Validate status code and body
            let (statusMatches, bodyMatches) = validateResponse(
                actual: (status: httpResponse.statusCode, body: responseBody),
                expected: testCase
            )

            let passed = statusMatches && bodyMatches

            return TestResult(
                testCase: testCase,
                actualStatus: httpResponse.statusCode,
                actualResponse: responseBody,
                passed: passed,
                statusMatches: statusMatches,
                bodyMatches: bodyMatches,
                error: nil,
                duration: duration
            )

        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return TestResult(
                testCase: testCase,
                passed: false,
                error: error.localizedDescription,
                duration: duration
            )
        }
    }

    private func buildURL(for testCase: TestCase) -> URL {
        let base = "http://\(serviceConfig.ip):\(serviceConfig.port)"
        let urlString = "\(base)\(testCase.path)"
        return URL(string: urlString)!
    }

    private func validateResponse(actual: (status: Int, body: [String: Any]), expected: TestCase)
        -> (Bool, Bool)
    {
        // Validate status code
        let statusMatches = actual.status == expected.expectedStatus

        // Validate response body
        let bodyMatches: Bool
        if expected.expectedResponse.isEmpty {
            // Empty expected response means we expect empty or error response
            bodyMatches = actual.body.isEmpty
        } else {
            // Deep comparison
            bodyMatches = JSONComparator.areEqual(actual.body, expected.expectedResponse)
        }

        return (statusMatches, bodyMatches)
    }

    private func printTestResult(_ result: TestResult) {
        let icon = result.passed ? "✓" : "✗"
        let durationMs = Int(result.duration * 1000)

        if result.passed {
            print("\u{001B}[32m  \(icon) \(result.testCase.key)\u{001B}[0m \u{001B}[90m(\(durationMs)ms)\u{001B}[0m")
        } else {
            print("\u{001B}[31m  \(icon) \(result.testCase.key)\u{001B}[0m \u{001B}[90m(\(durationMs)ms)\u{001B}[0m")

            if let error = result.error {
                print("    Error: \(error)")
            } else {
                if !result.statusMatches {
                    let actual = result.actualStatus ?? 0
                    print("\u{001B}[37m    Status: Expected \(result.testCase.expectedStatus), Got \(actual)\u{001B}[0m")
                }
                if !result.bodyMatches {
                    if result.testCase.expectedResponse.isEmpty {
                        print("\u{001B}[37m    Body: Expected empty {}, Got non-empty response\u{001B}[0m")
                    } else {
                        print("\u{001B}[37m    Body: Response does not match expected\u{001B}[0m")
                    }
                }
            }
        }
    }

    func printResults(_ results: TestResults) {
        print("\n=== Test Results ===")
        print("Total: \(results.total) tests")
        print("Passed: \(results.passed) (\(String(format: "%.1f", results.passRate))%)")
        print("Failed: \(results.failed) (\(String(format: "%.1f", 100.0 - results.passRate))%)")

        // if !results.failures.isEmpty {
        //     print("\nFailed Tests:")
        //     for (index, failure) in results.failures.enumerated() {
        //         print("  \(index + 1). \(failure.testCase.key)")
        //         if let error = failure.error {
        //             print("     Error: \(error)")
        //         } else {
        //             if !failure.statusMatches {
        //                 let actual = failure.actualStatus ?? 0
        //                 print(
        //                     "     Expected status: \(failure.testCase.expectedStatus), Actual: \(actual)"
        //                 )
        //             }
        //             if !failure.bodyMatches {
        //                 print("     Body mismatch")
        //             }
        //         }
        //     }
        // }
    }
}
