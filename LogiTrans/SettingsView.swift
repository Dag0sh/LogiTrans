import SwiftUI

struct SettingsView: View {
    @AppStorage("db_host") private var dbHost = ""
    @AppStorage("db_password") private var dbPassword = ""
    @Environment(\.dismiss) private var dismiss
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Подключение к базе данных") {
                    TextField("IP-адрес сервера", text: $dbHost)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    SecureField("Пароль", text: $dbPassword)
                }

                Section {
                    Button(action: testConnection) {
                        if isTesting {
                            HStack {
                                ProgressView()
                                Text("Проверяем...")
                            }
                        } else {
                            Text("Проверить соединение")
                        }
                    }
                    .disabled(isTesting || dbHost.isEmpty || dbPassword.isEmpty)
                }

                if let result = testResult {
                    Section {
                        Text(result)
                            .foregroundColor(result.contains("успешно") ? .green : .red)
                    }
                }

                Section("Параметры БД") {
                    LabeledContent("Пользователь", value: AppConfig.dbUser)
                    LabeledContent("Порт", value: "\(AppConfig.dbPort)")
                    LabeledContent("База данных", value: AppConfig.dbName)
                }
            }
            .navigationTitle("Настройки")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            do {
                await NetworkManager.shared.resetConnection()
                _ = try await NetworkManager.shared.getPoints()
                testResult = "Соединение успешно!"
            } catch {
                testResult = "Ошибка: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }
}
