import Foundation

@MainActor
final class WarehouseLoadViewModel: ObservableObject {
    @Published var loads: [WarehouseLoad] = []
    @Published var reports: [Report] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        isLoading = true
        error = nil
        do {
            async let loadsTask   = NetworkManager.shared.getWarehouseLoad()
            async let reportsTask = NetworkManager.shared.getReports()
            loads   = try await loadsTask
            reports = try await reportsTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
