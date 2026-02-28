import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct TestCase {
    let key: String
    let method: HTTPMethod
    let path: String
    let body: [String: Any]?
    let expectedStatus: Int
    let expectedResponse: [String: Any]
}

struct TestSuite {
    let name: String
    let testCases: [TestCase]

    init(name: String, path: String) throws {
        self.name = name

        let url = URL(fileURLWithPath: path)
        let pairs = try OrderedJSONDecoder.decode(from: url)

        var cases: [TestCase] = []
        for (key, dict) in pairs {
            guard
                let methodStr = dict["method"] as? String,
                let method = HTTPMethod(rawValue: methodStr.uppercased()),
                let casePath = dict["path"] as? String,
                let expectedStatus = dict["expectedStatus"] as? Int
            else {
                print("Warning: Skipping malformed test case '\(key)' (missing method, path, or expectedStatus)")
                continue
            }

            let body = dict["body"] as? [String: Any]
            let expectedResponse = dict["expectedResponse"] as? [String: Any] ?? [:]

            cases.append(TestCase(
                key: key,
                method: method,
                path: casePath,
                body: body,
                expectedStatus: expectedStatus,
                expectedResponse: expectedResponse
            ))
        }

        self.testCases = cases
    }
}
