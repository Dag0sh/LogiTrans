import SwiftUI

@MainActor
final class ClientsListViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var cargoByPhone: [String: [Cargo]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            clients = try await NetworkManager.shared.getClients()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadCargo(for phone: String) async {
        guard cargoByPhone[phone] == nil else { return }
        do {
            cargoByPhone[phone] = try await NetworkManager.shared.getCargoByClient(phone: phone)
        } catch {
            cargoByPhone[phone] = []
        }
    }
}

struct ClientsListView: View {
    var showCloseButton: Bool = false

    @StateObject private var vm = ClientsListViewModel()
    @State private var expandedPhone: String? = nil
    @State private var revealedPasswords: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            if vm.isLoading {
                ProgressView("Загрузка клиентов…")
            } else if let err = vm.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle).foregroundColor(.red)
                    Text(err).multilineTextAlignment(.center).foregroundColor(.secondary)
                    Button("Повторить") { Task { await vm.load() } }
                }
                .padding()
            } else if vm.clients.isEmpty {
                Text("Клиентов нет").foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.clients) { client in
                            clientCard(client)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Клиенты")
        .toolbar {
            if showCloseButton {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .task { await vm.load() }
    }

    @ViewBuilder
    private func clientCard(_ client: Client) -> some View {
        let isExpanded = expandedPhone == client.phone
        let passwordRevealed = revealedPasswords.contains(client.phone)

        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedPhone = isExpanded ? nil : client.phone
                }
                if !isExpanded {
                    Task { await vm.loadCargo(for: client.phone) }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(client.fio)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(client.phone)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(12)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Divider().padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 8) {
                    infoRow(icon: "house", label: "Адрес", value: client.address ?? "—")

                    HStack(spacing: 6) {
                        Image(systemName: "lock").foregroundColor(.secondary).frame(width: 18)
                        Text("Пароль:").font(.system(size: 13)).foregroundColor(.secondary)
                        if passwordRevealed {
                            Text(client.password ?? "—")
                                .font(.system(size: 13, design: .monospaced))
                        } else {
                            Text(String(repeating: "•", count: min(client.password?.count ?? 4, 8)))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            if passwordRevealed { revealedPasswords.remove(client.phone) }
                            else { revealedPasswords.insert(client.phone) }
                        } label: {
                            Image(systemName: passwordRevealed ? "eye.slash" : "eye")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                    }

                    Divider()

                    Text("Заказы")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    if let cargos = vm.cargoByPhone[client.phone] {
                        if cargos.isEmpty {
                            Text("Нет заказов")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(cargos) { cargo in
                                cargoRow(cargo, clientPhone: client.phone)
                            }
                        }
                    } else {
                        HStack { ProgressView(); Text("Загружаем…").font(.caption) }
                    }
                }
                .padding(12)
            }
        }
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(.secondary).frame(width: 18)
            Text("\(label):").font(.system(size: 13)).foregroundColor(.secondary)
            Text(value).font(.system(size: 13))
            Spacer()
        }
    }

    private func cargoRow(_ cargo: Cargo, clientPhone: String) -> some View {
        let role = cargo.senderPhone == clientPhone ? "отправитель" : "получатель"
        return HStack(spacing: 6) {
            Image(systemName: "shippingbox")
                .font(.system(size: 12))
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 1) {
                Text(cargo.track)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                Text("\(cargo.type) · \(cargo.delivery) · \(role)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(String(format: "%.0f ₽", cargo.price))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
