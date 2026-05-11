import Foundation

enum ConnectionStatus {
    case unknown, checking, ok, failed(String)
}

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var phone = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loggedInPosition: String?
    @Published var loggedInFio: String?
    @Published var connectionStatus: ConnectionStatus = .unknown

    var canLogin: Bool {
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    func checkConnection() async {
        connectionStatus = .checking
        do {
            try await NetworkManager.shared.testConnection()
            connectionStatus = .ok
        } catch {
            let desc = friendlyError(error)
            print("[Login] Ошибка проверки подключения: \(error)")
            connectionStatus = .failed(desc)
        }
    }

    private func friendlyError(_ error: Error) -> String {
        let raw = "\(error)"
        // socketError wraps a POSIX/NW error — extract the cause
        if raw.contains("socketError") {
            let nsErr = error as NSError
            let cause = nsErr.userInfo[NSUnderlyingErrorKey] as? NSError
            let posix = cause?.code ?? nsErr.code
            switch posix {
            case 61: return "Соединение отклонено (порт закрыт или PostgreSQL не запущен)"
            case 60: return "Таймаут подключения (хост недоступен или файрвол блокирует)"
            case 64, 65: return "Хост недоступен в сети"
            default:  return "Ошибка сокета (код \(posix)): проверьте IP и порт"
            }
        }
        if raw.contains("notConfigured") { return "Настройте адрес сервера в ⚙ Настройках" }
        if raw.contains("serverError") {  return "Ошибка сервера PostgreSQL: \(error.localizedDescription)" }
        return error.localizedDescription
    }

    func login() async {
        print("[Login] Попытка входа: телефон=\(phone), пароль — \(password.count) символов")
        isLoading = true
        errorMessage = nil
        do {
            let (position, fio) = try await NetworkManager.shared.login(phone: phone, password: password)
            if let pos = position {
                print("[Login] Успех: роль=\(pos), ФИО=\(fio ?? "—")")
                loggedInPosition = pos
                loggedInFio = fio
            } else {
                print("[Login] Неверные учётные данные для телефона \(phone)")
                errorMessage = "Неверный телефон или пароль"
            }
        } catch {
            print("[Login] Ошибка подключения: \(error)")
            errorMessage = "Ошибка подключения: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
