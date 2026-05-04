import Foundation

@MainActor
final class OperatorViewModel: ObservableObject {
    @Published var track = ""
    @Published var type = "мелкий"
    @Published var delivery = "стандартная"
    @Published var sender = ""
    @Published var receiver = ""
    @Published var mass: Double? = 0
    @Published var value: Double? = 0
    @Published var pack = false
    @Published var ins = false
    @Published var price: Double = 0
    @Published var point = ""
    @Published var slot = ""
    @Published var points: [String] = []
    @Published var statusMessage: String?
    @Published var isError = false

    var canCreate: Bool { !point.isEmpty && !points.isEmpty }

    func loadPoints() async {
        do {
            points = try await NetworkManager.shared.getPoints()
            if !points.isEmpty && point.isEmpty { point = points[0] }
            if points.isEmpty { setError("Нет доступных пунктов в БД") }
        } catch {
            setError(error.localizedDescription)
        }
    }

    func calculatePrice() async {
        do {
            price = try await NetworkManager.shared.calculatePrice(
                mass: mass, type: type, delivery: delivery, pack: pack, ins: ins)
        } catch {
            setError(error.localizedDescription)
        }
    }

    func createCargo(employeeFio: String) async {
        do {
            if price == 0 {
                price = try await NetworkManager.shared.calculatePrice(
                    mass: mass, type: type, delivery: delivery, pack: pack, ins: ins)
            }
            try await NetworkManager.shared.insertCargo(
                track: track, type: type, delivery: delivery,
                sender: sender, receiver: receiver, price: price,
                mass: mass, value: value, pack: pack, ins: ins)
            try await NetworkManager.shared.insertShipment(
                cargoTrack: track, pointName: point, slot: slot,
                status: "занято", employeeFio: employeeFio, date: Date())
            setSuccess("Создано!")
        } catch {
            setError(error.localizedDescription)
        }
    }

    private func setSuccess(_ msg: String) { statusMessage = msg; isError = false }
    private func setError(_ msg: String) { statusMessage = msg; isError = true }
}
