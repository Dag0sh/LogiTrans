import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var loggedInPosition: String?
    @State private var loggedInFio: String?
    @State private var isLoading: Bool = false
    @FocusState private var focusedField: Field?
    @State private var path: [String] = []

    enum Field {
        case phone, password
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()

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
                        TextField("Телефон", text: $phone)
                            .keyboardType(.phonePad)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .focused($focusedField, equals: .phone)

                        SecureField("Пароль", text: $password)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .focused($focusedField, equals: .password)
                    }
                    .padding(.horizontal, 22)

                    Button(action: {
                        isLoading = true
                        focusedField = nil
                        errorMessage = nil
                        Task {
                            do {
                                let (position, fio) = try await NetworkManager.shared.login(phone: phone, password: password)
                                if let pos = position {
                                    loggedInPosition = pos
                                    loggedInFio = fio
                                    path.append(pos)
                                } else {
                                    errorMessage = "Неверный телефон или пароль"
                                }
                            } catch let err {
                                errorMessage = getFriendlyError(err)
                            }
                            isLoading = false
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 5)
                            }
                            Text("Войти")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    .padding()
                    .background(isLoading || phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty ? Color.gray.opacity(0.25) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 22)

                    if let err = errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding(.top, 6)
                    }

                    Spacer()
                }
                .frame(maxWidth: 400)
            }
            .ignoresSafeArea(.keyboard)
            .navigationDestination(for: String.self) { pos in
                Group {
                    switch pos {
                    case "Руководитель":
                        LeaderView(currentEmployeeFio: loggedInFio ?? "")
                            .navigationBarBackButtonHidden(true)
                    case "Администратор":
                        AdminView()
                            .navigationBarBackButtonHidden(true)
                    case "Оператор":
                        OperatorView(currentEmployeeFio: loggedInFio ?? "")
                            .navigationBarBackButtonHidden(true)
                    case "Работник склада":
                        WarehouseView()
                            .navigationBarBackButtonHidden(true)
                    case "Менеджер":
                        WarehouseLoadView()
                            .navigationBarBackButtonHidden(true)
                    default:
                        Text("Неизвестная роль")
                            .navigationBarBackButtonHidden(true)
                    }
                }
            }
        }
    }

    func getFriendlyError(_ error: Error) -> String {
        let errStr = error.localizedDescription
        if errStr.contains("Неверный телефон") {
            return "Неверный телефон или пароль"
        } else {
            return "Ошибка входа, проверьте данные"
        }
    }
}
