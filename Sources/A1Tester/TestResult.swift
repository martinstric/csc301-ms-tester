import Foundation

struct TestResult {
    let testCase: TestCase
    let actualStatus: Int?
    let actualResponse: [String: Any]?
    let passed: Bool
    let statusMatches: Bool
    let bodyMatches: Bool
    let error: String?
    let duration: TimeInterval

    init(
        testCase: TestCase, actualStatus: Int? = nil, actualResponse: [String: Any]? = nil,
        passed: Bool, statusMatches: Bool = false, bodyMatches: Bool = false,
        error: String? = nil, duration: TimeInterval = 0
    ) {
        self.testCase = testCase
        self.actualStatus = actualStatus
        self.actualResponse = actualResponse
        self.passed = passed
        self.statusMatches = statusMatches
        self.bodyMatches = bodyMatches
        self.error = error
        self.duration = duration
    }
}

struct TestResults {
    var total: Int = 0
    var passed: Int = 0
    var failed: Int = 0
    var failures: [TestResult] = []

    mutating func add(_ result: TestResult) {
        total += 1
        if result.passed {
            passed += 1
        } else {
            failed += 1
            failures.append(result)
        }
    }

    mutating func merge(_ other: TestResults) {
        total += other.total
        passed += other.passed
        failed += other.failed
        failures.append(contentsOf: other.failures)
    }

    var passRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(passed) / Double(total) * 100.0
    }
}
