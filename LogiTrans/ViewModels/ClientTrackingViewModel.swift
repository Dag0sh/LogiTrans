import Foundation

@MainActor
final class ClientTrackingViewModel: ObservableObject {
    @Published var track = ""
    @Published var statuses: [Shipment] = []
    @Published var error: String?
    @Published var isLoading = false

    var canSearch: Bool { !track.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func search() async {
        isLoading = true
        error = nil
        statuses = []
        do {
            statuses = try await NetworkManager.shared.getCargoStatus(track: track)
            if statuses.isEmpty { error = "Груз не найден" }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
