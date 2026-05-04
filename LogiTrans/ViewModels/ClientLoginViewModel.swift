import Foundation

@MainActor
final class ClientLoginViewModel: ObservableObject {
    @Published var phone = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false

    var canLogin: Bool { !phone.isEmpty && !password.isEmpty }

    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let success = try await NetworkManager.shared.clientLogin(phone: phone, password: password)
            if success {
                isLoggedIn = true
            } else {
                errorMessage = "Неверный телефон или пароль"
            }
        } catch {
            errorMessage = "Ошибка подключения: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func logout() {
        isLoggedIn = false
        phone = ""
        password = ""
        errorMessage = nil
    }
}
