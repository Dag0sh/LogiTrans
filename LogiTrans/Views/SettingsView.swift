import SwiftUI

struct SettingsView: View {
    @AppStorage("db_host") private var dbHost = "192.168.50.56"
    @AppStorage("db_password") private var dbPassword = "1008"
    @Environment(\.dismiss) private var dismiss
    @State private var portText = "\(AppConfig.dbPort)"
    @State private var testResult: String?
    @State private var isTesting = false
    @State private var isDiscovering = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Подключение к базе данных") {
                    TextField("Хост", text: $dbHost)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)

                    HStack {
                        Text("Порт")
                        Spacer()
                        TextField("5432", text: $portText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: portText) { v in
                                if let p = Int(v) { AppConfig.dbPort = p }
                            }
                    }

                    SecureField("Пароль", text: $dbPassword)
                }

                Section {
                    Button(action: discoverHost) {
                        if isDiscovering {
                            HStack { ProgressView(); Text("Ищем сервер в сети…") }
                        } else {
                            Label("Найти сервер в локальной сети", systemImage: "network")
                        }
                    }
                    .disabled(isDiscovering || isTesting)

                    Button(action: testConnection) {
                        if isTesting {
                            HStack { ProgressView(); Text("Проверяем…") }
                        } else {
                            Text("Проверить соединение")
                        }
                    }
                    .disabled(isTesting || isDiscovering || dbHost.isEmpty || dbPassword.isEmpty)
                }

                if let result = testResult {
                    Section {
                        Text(result)
                            .foregroundColor(result.contains("успешно") ? .green : .red)
                    }
                }

                Section("Параметры БД") {
                    LabeledContent("Пользователь", value: AppConfig.dbUser)
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

    private func discoverHost() {
        isDiscovering = true
        testResult = nil
        Task {
            if let found = await DBDiscovery.findDBHost() {
                dbHost = found
                portText = "5432"
                AppConfig.dbPort = 5432
                await NetworkManager.shared.resetConnection()
                testResult = "Найден сервер: \(found)"
            } else {
                testResult = "Сервер не найден. Убедитесь, что устройство в одной сети с ПК."
            }
            isDiscovering = false
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
