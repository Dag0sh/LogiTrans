import Foundation

@MainActor
final class AdminViewModel: ObservableObject {
    // Cargo
    @Published var cargoTrack = ""
    @Published var newCargoType = ""
    @Published var newDelivery = ""
    @Published var newPrice: Double? = nil
    @Published var newMass: Double? = nil
    @Published var newValue: Double? = nil
    @Published var newPack = false
    @Published var newIns = false

    // Client
    @Published var clientPhone = ""
    @Published var newClientAddress = ""
    @Published var newClientFio = ""
    @Published var newClientPassword = ""

    // Point
    @Published var pointName = ""
    @Published var newPointPhone = ""
    @Published var newPointAddress = ""

    // Employee
    @Published var employeeFio = ""
    @Published var newEmployeePosition = "Оператор"
    @Published var newEmployeePhone = ""
    @Published var newEmployeePassword = ""

    @Published var statusMessage: String?
    @Published var isError = false

    // MARK: - Cargo

    func createCargo() async {
        do {
            let price = try await NetworkManager.shared.calculatePrice(
                mass: newMass, type: newCargoType, delivery: newDelivery, pack: newPack, ins: newIns)
            try await NetworkManager.shared.insertCargo(
                track: cargoTrack, type: newCargoType, delivery: newDelivery,
                sender: "", receiver: "", price: price,
                mass: newMass, value: newValue, pack: newPack, ins: newIns)
            setSuccess("Создано!")
        } catch { setError(error) }
    }

    func updateCargo() async {
        do {
            try await NetworkManager.shared.updateCargo(
                track: cargoTrack, newType: newCargoType, newDelivery: newDelivery,
                newPrice: newPrice ?? 0, newMass: newMass ?? 0,
                newValue: newValue ?? 0, newPack: newPack, newIns: newIns)
            setSuccess("Обновлено!")
        } catch { setError(error) }
    }

    func deleteCargo() async {
        do {
            try await NetworkManager.shared.deleteCargo(track: cargoTrack)
            setSuccess("Удалено!")
        } catch { setError(error) }
    }

    // MARK: - Client

    func createClient() async {
        do {
            try await NetworkManager.shared.insertClient(
                phone: clientPhone, address: newClientAddress,
                fio: newClientFio, password: newClientPassword)
            setSuccess("Создано!")
        } catch { setError(error) }
    }

    func updateClient() async {
        do {
            try await NetworkManager.shared.updateClient(
                phone: clientPhone, newAddress: newClientAddress,
                newFio: newClientFio, newPassword: newClientPassword)
            setSuccess("Обновлено!")
        } catch { setError(error) }
    }

    func deleteClient() async {
        do {
            try await NetworkManager.shared.deleteClient(phone: clientPhone)
            setSuccess("Удалено!")
        } catch { setError(error) }
    }

    // MARK: - Point

    func createPoint() async {
        do {
            try await NetworkManager.shared.insertPoint(
                name: pointName, phone: newPointPhone, address: newPointAddress)
            setSuccess("Создано!")
        } catch { setError(error) }
    }

    func updatePoint() async {
        do {
            try await NetworkManager.shared.updatePoint(
                name: pointName, newPhone: newPointPhone, newAddress: newPointAddress)
            setSuccess("Обновлено!")
        } catch { setError(error) }
    }

    func deletePoint() async {
        do {
            try await NetworkManager.shared.deletePoint(name: pointName)
            setSuccess("Удалено!")
        } catch { setError(error) }
    }

    // MARK: - Employee

    func createEmployee() async {
        do {
            try await NetworkManager.shared.insertEmployee(
                fio: employeeFio, position: newEmployeePosition,
                phone: newEmployeePhone, password: newEmployeePassword)
            setSuccess("Создано!")
        } catch { setError(error) }
    }

    func updateEmployee() async {
        do {
            try await NetworkManager.shared.updateEmployee(
                fio: employeeFio, newPosition: newEmployeePosition,
                newPhone: newEmployeePhone, newPassword: newEmployeePassword)
            setSuccess("Обновлено!")
        } catch { setError(error) }
    }

    func deleteEmployee() async {
        do {
            try await NetworkManager.shared.deleteEmployee(fio: employeeFio)
            setSuccess("Удалено!")
        } catch { setError(error) }
    }

    // MARK: - Helpers

    private func setSuccess(_ msg: String) { statusMessage = msg; isError = false }
    private func setError(_ error: Error) { statusMessage = error.localizedDescription; isError = true }
}
