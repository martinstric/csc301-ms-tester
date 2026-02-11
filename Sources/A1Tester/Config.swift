import Foundation

struct ServiceConfig: Codable {
    let port: Int
    let ip: String
}

struct Config: Codable {
    let UserService: ServiceConfig
    let OrderService: ServiceConfig
    let ProductService: ServiceConfig
    let InterServiceCommunication: ServiceConfig?

    func getService(_ name: String) -> ServiceConfig? {
        switch name.lowercased() {
        case "user", "userservice":
            return UserService
        case "order", "orderservice":
            return OrderService
        case "product", "productservice":
            return ProductService
        case "iscs", "interservicecommunication":
            return InterServiceCommunication
        default:
            return nil
        }
    }

    static func load(from path: String) throws -> Config {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(Config.self, from: data)
    }
}
