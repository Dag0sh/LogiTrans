import SwiftUI

struct ClientLoginView: View {
    @StateObject private var vm = ClientLoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var path: [Bool] = []

    enum Field { case phone, password }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Вход для клиента")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.gray)
                        Divider().background(Color(.systemGray3)).padding(.horizontal, 40)
                    }
                    .padding(.top, 36)

                    VStack(spacing: 16) {
                        TextField("Телефон", text: $vm.phone)
                            .keyboardType(.phonePad)
                            .autocapitalization(.none)
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
                            if vm.isLoggedIn { path.append(true) }
                        }
                    } label: {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity).padding()
                        } else {
                            Text("Войти")
                                .frame(maxWidth: .infinity).padding()
                                .foregroundColor(.white)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray)))
                                .font(.headline)
                        }
                    }
                    .disabled(vm.isLoading || !vm.canLogin)
                    .padding(.horizontal, 22).padding(.top, 6)

                    if let err = vm.errorMessage {
                        Text(err)
                            .foregroundColor(.red).font(.subheadline)
                            .padding(.horizontal, 28).multilineTextAlignment(.center)
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
                            Button {
                                path.removeLast()
                                vm.logout()
                            } label: {
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
}
