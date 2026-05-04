import SwiftUI

struct ContentView: View {
    @State private var selectedRole: AppRole? = nil
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            if selectedRole == nil {
                ZStack {
                    Color(.systemGray6).ignoresSafeArea()
                    VStack(spacing: 36) {
                        VStack(spacing: 12) {
                            Text("Добро пожаловать в ЛогиТранс")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.gray)
                            Text("Выберите вашу роль для входа")
                                .foregroundColor(.secondary)
                                .font(.title3)
                        }
                        .padding(.top, 70)

                        VStack(spacing: 28) {
                            Button { selectedRole = .employee } label: {
                                HStack {
                                    Image(systemName: "person.crop.rectangle").foregroundColor(.blue)
                                    Text("Сотрудник").font(.system(size: 20, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white)
                                    .shadow(color: Color(.black).opacity(0.06), radius: 3, x: 0, y: 1))
                            }
                            Button { selectedRole = .client } label: {
                                HStack {
                                    Image(systemName: "person.circle").foregroundColor(.green)
                                    Text("Клиент").font(.system(size: 20, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white)
                                    .shadow(color: Color(.black).opacity(0.06), radius: 3, x: 0, y: 1))
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                    .frame(maxWidth: 420)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
            } else if selectedRole == .employee {
                VStack(spacing: 0) {
                    backButton { selectedRole = nil }
                    LoginView().padding(.top, 8)
                }
            } else {
                VStack(spacing: 0) {
                    backButton { selectedRole = nil }
                    ClientLoginView().padding(.top, 8)
                }
            }
        }
    }

    private func backButton(action: @escaping () -> Void) -> some View {
        HStack {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Назад")
                }
                .foregroundColor(.blue)
                .padding(.vertical, 6).padding(.horizontal, 10)
                .background(Color(.systemGray5)).cornerRadius(8)
            }
            Spacer()
        }
        .padding(.top, 14).padding(.horizontal, 20)
    }
}
