import Foundation

struct JSONComparator {
    static func areEqual(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        // Check key count
        guard lhs.keys.count == rhs.keys.count else { return false }

        // Compare each key-value pair
        for (key, lhsValue) in lhs {
            guard let rhsValue = rhs[key] else { return false }

            if !valuesEqual(lhsValue, rhsValue) {
                return false
            }
        }

        return true
    }

    private static func valuesEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        // Handle different types
        switch (lhs, rhs) {
        case (let l as String, let r as String):
            // Case-insensitive comparison for strings (e.g., password hashes)
            return l.uppercased() == r.uppercased()

        case (let l as Int, let r as Int):
            return l == r

        case (let l as Double, let r as Double):
            // Floating point comparison with tolerance
            return abs(l - r) < 0.001

        case (let l as Float, let r as Float):
            return abs(l - r) < 0.001

        case (let l as Bool, let r as Bool):
            return l == r

        case (let l as [String: Any], let r as [String: Any]):
            // Recursive for nested objects
            return areEqual(l, r)

        case (let l as [Any], let r as [Any]):
            return arraysEqual(l, r)

        case (_ as NSNull, _ as NSNull):
            return true

        default:
            // Try to compare as numbers if possible
            if let lNum = asNumber(lhs), let rNum = asNumber(rhs) {
                return abs(lNum - rNum) < 0.001
            }
            return false
        }
    }

    private static func arraysEqual(_ lhs: [Any], _ rhs: [Any]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { valuesEqual($0, $1) }
    }

    private static func asNumber(_ value: Any) -> Double? {
        if let num = value as? Int {
            return Double(num)
        } else if let num = value as? Double {
            return num
        } else if let num = value as? Float {
            return Double(num)
        }
        return nil
    }
}
