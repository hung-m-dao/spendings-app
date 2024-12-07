import Foundation

enum NetworkConfiguration {
    static let baseUrl: String = "https://firefly.lanhnguyen.dev/api"
    static let token: String = NetworkConfiguration.environmentVariable(named: "api_token")

    private static func environmentVariable(named: String) -> String {
            let processInfo = ProcessInfo.processInfo
            guard let value = processInfo.environment[named] else {
                print("Missing Environment Variabled : '\(named)'")
                return ""
            }
            return value
        }
}
