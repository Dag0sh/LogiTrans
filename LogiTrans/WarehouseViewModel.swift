import Foundation

@MainActor
final class WarehouseViewModel: ObservableObject {
    @Published var point = ""
    @Published var points: [String] = []
    @Published var shipments: [Shipment] = []
    @Published var statusMessage: String?
    @Published var isError = false

    func loadPoints() async {
        do {
            points = try await NetworkManager.shared.getPoints()
            if !points.isEmpty && point.isEmpty { point = points[0] }
            if points.isEmpty { setError("Нет доступных пунктов в БД") }
        } catch {
            setError(error.localizedDescription)
        }
    }

    func loadShipments() async {
        do {
            shipments = try await NetworkManager.shared.getShipments(by: point)
            statusMessage = nil
            isError = false
        } catch {
            setError(error.localizedDescription)
        }
    }

    func updateShipment(track: String, slot: String, status: String, fio: String) async {
        do {
            try await NetworkManager.shared.updateShipment(
                cargoTrack: track, pointName: point,
                newSlot: slot, newStatus: status, newEmployeeFio: fio, newDate: Date())
            if status == "доставлено" {
                try await NetworkManager.shared.archiveShipment(cargoTrack: track)
            }
            await loadShipments()
            setSuccess("Обновлено!")
        } catch {
            setError(error.localizedDescription)
        }
    }

    private func setSuccess(_ msg: String) { statusMessage = msg; isError = false }
    private func setError(_ msg: String) { statusMessage = msg; isError = true }
}
