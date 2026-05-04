import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var phone = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loggedInPosition: String?
    @Published var loggedInFio: String?

    var canLogin: Bool {
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let (position, fio) = try await NetworkManager.shared.login(phone: phone, password: password)
            if let pos = position {
                loggedInPosition = pos
                loggedInFio = fio
            } else {
                errorMessage = "Неверный телефон или пароль"
            }
        } catch {
            errorMessage = "Ошибка подключения: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
