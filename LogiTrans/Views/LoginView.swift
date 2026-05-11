import SwiftUI

private struct QuickUser {
    let label: String
    let phone: String
    let password: String
}

private let quickUsers: [QuickUser] = [
    QuickUser(label: "Руководитель", phone: "+79161111111", password: "leader2026"),
    QuickUser(label: "Администратор", phone: "+79162222222", password: "admin2026"),
    QuickUser(label: "Оператор",      phone: "+79163333333", password: "oper2026"),
    QuickUser(label: "Склад",         phone: "+79164444444", password: "wh2026"),
    QuickUser(label: "Менеджер",      phone: "+79165555555", password: "mgr2026"),
]

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var path: [String] = []
    @State private var showQuickFill = false
    @State private var isDiscovering = false
    @AppStorage("db_host") private var dbHost = "172.20.10.2"

    enum Field { case phone, password }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Вход для сотрудника")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.gray)
                        Divider()
                            .background(Color(.systemGray3))
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 16) {
                        TextField("Телефон", text: $vm.phone)
                            .keyboardType(.phonePad)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
                                .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1))
                            .focused($focusedField, equals: .phone)

                        SecureField("Пароль", text: $vm.password)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
                                .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1))
                            .focused($focusedField, equals: .password)
                    }
                    .padding(.horizontal, 22)

                    Button {
                        focusedField = nil
                        Task {
                            await vm.login()
                            if let pos = vm.loggedInPosition { path.append(pos) }
                        }
                    } label: {
                        HStack {
                            if vm.isLoading { ProgressView().padding(.trailing, 5) }
                            Text("Войти").font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(vm.isLoading || !vm.canLogin)
                    .padding()
                    .background(vm.isLoading || !vm.canLogin ? Color.gray.opacity(0.25) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 22)

                    HStack(spacing: 10) {
                        Button {
                            focusedField = nil
                            Task { await vm.checkConnection() }
                        } label: {
                            HStack(spacing: 6) {
                                if case .checking = vm.connectionStatus {
                                    ProgressView().scaleEffect(0.85)
                                } else {
                                    Image(systemName: "network")
                                }
                                Text("Проверить подключение")
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }
                        .disabled({ if case .checking = vm.connectionStatus { return true }; return false }())
                        .foregroundColor(.blue)

                        Spacer()

                        switch vm.connectionStatus {
                        case .ok:
                            Label("Подключено", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        case .failed:
                            Label("Нет связи", systemImage: "xmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 22)

                    if case .failed(let msg) = vm.connectionStatus {
                        Text(msg)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 22)
                            .padding(.top, -10)
                    }

                    if let err = vm.errorMessage {
                        VStack(spacing: 10) {
                            Text(err)
                                .foregroundColor(.red)
                                .font(.system(size: 16, weight: .semibold))
                                .multilineTextAlignment(.center)

                            if err.contains("подключени") || err.contains("Настройте") {
                                Button {
                                    isDiscovering = true
                                    vm.errorMessage = nil
                                    Task {
                                        if let found = await DBDiscovery.findDBHost() {
                                            dbHost = found
                                            await NetworkManager.shared.resetConnection()
                                            vm.errorMessage = "Сервер найден: \(found). Попробуйте войти снова."
                                        } else {
                                            vm.errorMessage = "Сервер не найден. Убедитесь, что ПК в одной Wi-Fi сети."
                                        }
                                        isDiscovering = false
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if isDiscovering {
                                            ProgressView().scaleEffect(0.8)
                                            Text("Ищем сервер…")
                                        } else {
                                            Image(systemName: "network")
                                            Text("Найти сервер автоматически")
                                        }
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                }
                                .disabled(isDiscovering)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 6)
                        .padding(.horizontal, 22)
                    }

                    Divider().padding(.horizontal, 22)

                    DisclosureGroup("Тестовые аккаунты", isExpanded: $showQuickFill) {
                        VStack(spacing: 8) {
                            ForEach(quickUsers, id: \.label) { user in
                                Button {
                                    vm.phone = user.phone
                                    vm.password = user.password
                                    focusedField = nil
                                    Task {
                                        await vm.login()
                                        if let pos = vm.loggedInPosition { path.append(pos) }
                                    }
                                } label: {
                                    HStack {
                                        Text(user.label)
                                            .font(.system(size: 15, weight: .medium))
                                        Spacer()
                                        Text(user.phone)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 22)
                    .accentColor(.blue)

                    Spacer()
                }
                .frame(maxWidth: 400)
            }
            .ignoresSafeArea(.keyboard)
            .navigationDestination(for: String.self) { pos in
                Group {
                    switch pos {
                    case "Руководитель":
                        LeaderView(currentEmployeeFio: vm.loggedInFio ?? "")
                            .navigationBarBackButtonHidden(true)
                    case "Администратор":
                        AdminView().navigationBarBackButtonHidden(true)
                    case "Оператор":
                        OperatorView(currentEmployeeFio: vm.loggedInFio ?? "")
                            .navigationBarBackButtonHidden(true)
                    case "Работник склада":
                        WarehouseView().navigationBarBackButtonHidden(true)
                    case "Менеджер":
                        ManagerView().navigationBarBackButtonHidden(true)
                    default:
                        Text("Неизвестная роль").navigationBarBackButtonHidden(true)
                    }
                }
            }
        }
    }
}
