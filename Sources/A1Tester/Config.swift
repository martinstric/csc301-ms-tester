import Foundation

struct ServiceConfig: Codable {
    let port: Int
    let ip: String
}

struct Config {
    private let services: [String: ServiceConfig]

    init(_ services: [String: ServiceConfig]) {
        self.services = services
    }

    /// Case-insensitive lookup. "order" matches "OrderService", "order", "ORDER", etc.
    func getService(_ name: String) -> ServiceConfig? {
        // 1. Exact case-insensitive match
        if let match = services.first(where: { $0.key.lowercased() == name.lowercased() }) {
            return match.value
        }
        // 2. Strip the word "service" from both sides and compare
        let stripped = name.lowercased().replacingOccurrences(of: "service", with: "")
        return services.first(where: {
            $0.key.lowercased().replacingOccurrences(of: "service", with: "") == stripped
        })?.value
    }

    static func load(from path: String) throws -> Config {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let dict = try decoder.decode([String: ServiceConfig].self, from: data)
        return Config(dict)
    }
}
