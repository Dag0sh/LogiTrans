import SwiftUI

struct ClientLoginView: View {
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoggedIn: Bool = false
    @State private var isLoading: Bool = false
    @FocusState private var focusedField: Field?
    @State private var path: [Bool] = []

    enum Field {
        case phone, password
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Вход для клиента")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.gray)
                        Divider()
                            .background(Color(.systemGray3))
                            .padding(.horizontal, 40)
                    }.padding(.top, 36)
                    
                    VStack(spacing: 16) {
                        TextField("Телефон", text: $phone)
                            .keyboardType(.phonePad)
                            .autocapitalization(.none)
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
                        Task {
                            do {
                                let success = try await NetworkManager.shared.clientLogin(phone: phone, password: password)
                                if success {
                                    isLoggedIn = true
                                    errorMessage = nil
                                    path.append(true)
                                } else {
                                    errorMessage = "Неверный телефон или пароль"
                                }
                            } catch let err {
                                errorMessage = getFriendlyError(err)
                            }
                            isLoading = false
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Войти")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray))
                                )
                                .font(.headline)
                        }
                    }
                    .disabled(isLoading || phone.isEmpty || password.isEmpty)
                    .padding(.horizontal, 22)
                    .padding(.top, 6)

                    if let err = errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal, 28)
                            .transition(.opacity)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .ignoresSafeArea(.keyboard)
            .navigationDestination(for: Bool.self) { _ in
                ClientTrackingView()
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                path.removeLast()
                                isLoggedIn = false
                                phone = ""
                                password = ""
                                errorMessage = nil
                            }) {
                                HStack {
                                    Image(systemName: "chevron.backward")
                                    Text("Назад")
                                }
                            }
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
