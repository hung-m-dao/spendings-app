import Foundation

enum NetworkConfiguration {
    static let baseUrl: String = "https://firefly.lanhnguyen.dev/api"
    static let token: String = NetworkConfiguration.valueFromPlist(named: "token")
    static let currentUser: String = NetworkConfiguration.valueFromPlist(named: "user")

    private static func valueFromPlist(named: String) -> String {
        // Locate the plist file in the app bundle
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dictionary = NSDictionary(contentsOfFile: path),
           let token = dictionary[named] as? String {
            return token
        }
        return ""
    }
}
