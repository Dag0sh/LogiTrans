import Foundation

enum AppRole { case employee, client }

struct Client: Identifiable {
    var id: String { phone }
    let phone: String
    let address: String?
    let fio: String
    let password: String?
}

struct Point: Identifiable {
    var id: String { name }
    let name: String
    let phone: String?
    let address: String?
}

struct Employee: Identifiable {
    var id: String { fio }
    let fio: String
    let position: String
    let phone: String
    let password: String?
}

struct Cargo: Identifiable {
    var id: String { track }
    let track: String
    let type: String
    let delivery: String
    let senderPhone: String
    let receiverPhone: String
    let price: Double
    let mass: Double?
    let value: Double?
    let packaging: Bool
    let insurance: Bool
}

struct Shipment: Identifiable, Equatable {
    var id: String { cargoTrack + pointName }
    let cargoTrack: String
    let pointName: String
    let slot: String
    let status: String
    let employeeFio: String?
    let date: Date

    static func == (lhs: Shipment, rhs: Shipment) -> Bool {
        lhs.cargoTrack == rhs.cargoTrack && lhs.pointName == rhs.pointName &&
        lhs.slot == rhs.slot && lhs.status == rhs.status &&
        lhs.employeeFio == rhs.employeeFio && lhs.date == rhs.date
    }
}

struct Report: Identifiable {
    var id: String { "\(period.timeIntervalSince1970)-\(cargoType)" }
    let period: Date
    let income: Double
    let count: Int
    let avgPrice: Double
    let cargoType: String
}

struct WarehouseLoad: Identifiable {
    var id: String { pointName }
    let pointName: String
    let occupiedSlots: Int
}
