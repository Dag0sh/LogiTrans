import SwiftUI

struct ContentView: View {
    @State private var selectedRole: String? = nil

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
                            Button(action: {
                                selectedRole = "Employee"
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.rectangle")
                                        .foregroundColor(.blue)
                                    Text("Сотрудник")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .shadow(color: Color(.black).opacity(0.06), radius: 3, x: 0, y: 1)
                                )
                            }
                            Button(action: {
                                selectedRole = "Client"
                            }) {
                                HStack {
                                    Image(systemName: "person.circle")
                                        .foregroundColor(.green)
                                    Text("Клиент")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .shadow(color: Color(.black).opacity(0.06), radius: 3, x: 0, y: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                    .frame(maxWidth: 420)
                }
            } else if selectedRole == "Employee" {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            selectedRole = nil
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Назад")
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 20)
                    LoginView()
                        .padding(.top, 8)
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            selectedRole = nil
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Назад")
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 20)
                    ClientLoginView()
                        .padding(.top, 8)
                }
            }
        }
    }
}
