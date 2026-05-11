import Foundation

enum AppConfig {
    static var dbHost: String {
        get {
            let v = UserDefaults.standard.string(forKey: "db_host") ?? ""
            return v.isEmpty ? "192.168.50.56" : v
        }
        set { UserDefaults.standard.set(newValue, forKey: "db_host") }
    }
    static var dbPassword: String {
        get {
            let v = UserDefaults.standard.string(forKey: "db_password") ?? ""
            return v.isEmpty ? "1008" : v
        }
        set { UserDefaults.standard.set(newValue, forKey: "db_password") }
    }
    static var dbPort: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "db_port")
            return v == 0 ? 5432 : v
        }
        set { UserDefaults.standard.set(newValue, forKey: "db_port") }
    }
    static let dbUser = "dagosh"
    static let dbName = "logitrans_golikov_a_08"
    static var isConfigured: Bool { !dbHost.isEmpty && !dbPassword.isEmpty }
}
