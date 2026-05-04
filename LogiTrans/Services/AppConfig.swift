import Foundation

enum AppConfig {
    static var dbHost: String {
        get { UserDefaults.standard.string(forKey: "db_host") ?? "172.20.10.2" }
        set { UserDefaults.standard.set(newValue, forKey: "db_host") }
    }
    static var dbPassword: String {
        get { UserDefaults.standard.string(forKey: "db_password") ?? "1008" }
        set { UserDefaults.standard.set(newValue, forKey: "db_password") }
    }
    static let dbPort = 5432
    static let dbUser = "dagosh"
    static let dbName = "logitrans_golikov_a_08"
    static var isConfigured: Bool { !dbHost.isEmpty && !dbPassword.isEmpty }
}
