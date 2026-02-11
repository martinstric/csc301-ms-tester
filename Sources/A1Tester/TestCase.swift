import Foundation

enum EntityType: String {
    case user
    case product
    case order

    var endpoint: String {
        return "/\(self.rawValue)"
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct TestCase {
    let key: String
    let payload: [String: Any]
    let expectedResponse: [String: Any]
    let expectedStatus: Int
    let entityType: EntityType
    let httpMethod: HTTPMethod
    let endpoint: String

    init(key: String, payload: [String: Any], expectedResponse: [String: Any]) {
        self.key = key
        self.payload = payload
        self.expectedResponse = expectedResponse

        // Parse entity type from key (first segment)
        let components = key.split(separator: "_")
        if let firstComponent = components.first {
            let entityString = String(firstComponent).lowercased()
            self.entityType = EntityType(rawValue: entityString) ?? .order
        } else {
            self.entityType = .order
        }

        // Parse expected status code from key
        // Format: entity_operation_statusCode_identifier
        // Status code may contain comma: "404,401"
        var statusCode = 200
        for component in components {
            let compStr = String(component)
            // Check if component contains a digit and extract first status code
            if let match = compStr.range(of: "\\d+", options: .regularExpression),
                let code = Int(compStr[match])
            {
                statusCode = code
                break
            }
        }
        self.expectedStatus = statusCode

        // Determine HTTP method and endpoint
        if payload.keys.count == 1 && payload["id"] != nil {
            // GET request: only has "id" field
            self.httpMethod = .get
            if let id = payload["id"] {
                self.endpoint = "\(entityType.endpoint)/\(id)"
            } else {
                self.endpoint = entityType.endpoint
            }
        } else {
            // POST request: has "command" or other fields
            self.httpMethod = .post
            self.endpoint = entityType.endpoint
        }
    }
}

struct TestSuite {
    let name: String
    let entityType: EntityType
    let testCases: [TestCase]

    init(name: String, entityType: EntityType, payloadsPath: String, responsesPath: String) throws {
        self.name = name
        self.entityType = entityType

        // Load payloads and responses using ordered decoder
        let payloadURL = URL(fileURLWithPath: payloadsPath)
        let responseURL = URL(fileURLWithPath: responsesPath)

        let payloadPairs = try OrderedJSONDecoder.decode(from: payloadURL)
        let responsePairs = try OrderedJSONDecoder.decode(from: responseURL)

        // Convert response pairs to dictionary for lookup
        var responseDict: [String: [String: Any]] = [:]
        for (key, value) in responsePairs {
            responseDict[key] = value
        }

        // Create test cases preserving order from payload file
        var cases: [TestCase] = []
        for (key, payloadValue) in payloadPairs {
            let expectedResponse = responseDict[key] ?? [:]
            let testCase = TestCase(
                key: key, payload: payloadValue, expectedResponse: expectedResponse)
            cases.append(testCase)
        }

        self.testCases = cases
    }
}
