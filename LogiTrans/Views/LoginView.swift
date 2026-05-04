import SwiftUI

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var path: [String] = []

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

                    if let err = vm.errorMessage {
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
                        WarehouseLoadView().navigationBarBackButtonHidden(true)
                    default:
                        Text("Неизвестная роль").navigationBarBackButtonHidden(true)
                    }
                }
            }
        }
    }
}
