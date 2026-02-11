import Foundation

func runTester() async {
    // Parse command line arguments
    let arguments = CommandLine.arguments

    // Default configuration
    var configPath = "./config.json"
    var serviceType: String? = nil
    var ipOverride: String? = nil
    var portOverride: Int? = nil
    var testPath = "./tests/testcases"

    // Parse arguments
    var i = 1
    while i < arguments.count {
        let arg = arguments[i]

        switch arg {
        case "--config", "-c":
            if i + 1 < arguments.count {
                configPath = arguments[i + 1]
                i += 1
            }

        case "--service", "-s":
            if i + 1 < arguments.count {
                serviceType = arguments[i + 1]
                i += 1
            }

        case "--ip":
            if i + 1 < arguments.count {
                ipOverride = arguments[i + 1]
                i += 1
            }

        case "--port":
            if i + 1 < arguments.count {
                if let port = Int(arguments[i + 1]) {
                    portOverride = port
                }
                i += 1
            }

        case "--testpath", "-t":
            if i + 1 < arguments.count {
                testPath = arguments[i + 1]
                i += 1
            }

        case "--help", "-h":
            printUsage()
            exit(0)

        default:
            break
        }

        i += 1
    }

    print("=== Swift Microservice Tester ===")
    print("Configuration: \(configPath)")

    // Load configuration
    let config: Config
    do {
        config = try Config.load(from: configPath)
    } catch {
        print("Error: Failed to load config from \(configPath)")
        print("  \(error.localizedDescription)")
        exit(1)
    }

    guard let serviceType else {
        printUsage()
        exit(1)
    }

    // Determine target service (default to Order service)
    let targetServiceName = serviceType.lowercased()
    let entityType: EntityType

    switch targetServiceName {
    case "user", "userservice":
        entityType = .user
    case "product", "productservice":
        entityType = .product
    case "order", "orderservice":
        entityType = .order
    default:
        print("Error: Invalid service type '\(targetServiceName)'")
        print("Valid options: user, product, order")
        exit(1)
    }

    // Get service configuration
    guard var serviceConfig = config.getService(targetServiceName) else {
        print("Error: Service '\(targetServiceName)' not found in config")
        exit(1)
    }

    // Apply CLI overrides
    if let ip = ipOverride {
        serviceConfig = ServiceConfig(port: serviceConfig.port, ip: ip)
    }
    if let port = portOverride {
        serviceConfig = ServiceConfig(port: port, ip: serviceConfig.ip)
    }

    print(
        "Target: \(entityType.rawValue.capitalized) Service (\(serviceConfig.ip):\(serviceConfig.port))"
    )
    print("Test cases: \(testPath)")

    // Create test runner
    let runner = TestRunner(serviceConfig: serviceConfig, testBasePath: testPath)

    // Load and run tests
    do {
        let suite = try runner.loadTestSuite(for: entityType)
        let results = await runner.runAllTests(suite)
        runner.printResults(results)

        // Exit with appropriate code
        exit(results.failed > 0 ? 1 : 0)
    } catch {
        print("\nFatal error: \(error.localizedDescription)")
        exit(1)
    }
}

func printUsage() {
    print(
        """
        Usage: a1-tester [service] [options]

        Required Option:
          --service, -s <name>  Service to test: user, product, or order

        Options:
          --config, -c <path>   Path to config.json (default: ./config.json)
          --ip <ip>             Override service IP from config
          --port <port>         Override service port from config
          --testpath <path>     Path to test cases directory (default: ./instructions/CSC301_A1_testcases)
          --help, -h            Show this help message

        Examples:
          a1-tester
          a1-tester --service user
          a1-tester --service product --ip 127.0.0.1 --port 15000
          a1-tester --config ./custom-config.json --testpath ./tests
        """)
}

// Entry point
await runTester()
