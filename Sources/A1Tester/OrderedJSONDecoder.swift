import Foundation

class OrderedJSONDecoder {
    static func decode(from url: URL) throws -> [(String, [String: Any])] {
        let data = try Data(contentsOf: url)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Invalid UTF-8 data")
            )
        }

        // Parse JSON while maintaining key order
        var results: [(String, [String: Any])] = []

        // Use JSONSerialization to parse the JSON
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [], debugDescription: "Root object is not a dictionary")
            )
        }

        // Extract keys in the order they appear in the raw JSON string
        let orderedKeys = extractOrderedKeys(from: jsonString)

        // Build ordered array using extracted keys
        for key in orderedKeys {
            if let value = jsonObject[key] as? [String: Any] {
                results.append((key, value))
            }
        }

        // If we couldn't extract ordered keys (shouldn't happen), fall back to dictionary order
        if results.isEmpty {
            results = jsonObject.compactMap { key, value in
                if let dict = value as? [String: Any] {
                    return (key, dict)
                }
                return nil
            }
        }

        return results
    }

    private static func extractOrderedKeys(from jsonString: String) -> [String] {
        var keys: [String] = []
        var inString = false
        var escaped = false
        var currentKey = ""
        var depth = 0
        var isKey = false

        for char in jsonString {
            if escaped {
                escaped = false
                if isKey {
                    currentKey.append(char)
                }
                continue
            }

            if char == "\\" {
                escaped = true
                continue
            }

            if char == "\"" {
                inString.toggle()
                if !inString && isKey && !currentKey.isEmpty && depth == 1 {
                    keys.append(currentKey)
                    currentKey = ""
                    isKey = false
                }
                if inString && depth == 1 {
                    isKey = true
                    currentKey = ""
                }
                continue
            }

            if !inString {
                if char == "{" {
                    depth += 1
                } else if char == "}" {
                    depth -= 1
                }
            }

            if inString && isKey {
                currentKey.append(char)
            }
        }

        return keys
    }
}
