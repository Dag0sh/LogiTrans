import Foundation

@MainActor
final class WarehouseLoadViewModel: ObservableObject {
    @Published var loads: [WarehouseLoad] = []
    @Published var error: String?

    func loadData() async {
        do {
            loads = try await NetworkManager.shared.getWarehouseLoad()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
