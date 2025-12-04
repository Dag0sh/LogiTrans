import Foundation

struct Client {
    let phone: String
    let address: String?
    let fio: String
    let password: String?
}

struct Point {
    let name: String
    let phone: String?
    let address: String?
}

struct Employee {
    let fio: String
    let position: String
    let phone: String
    let password: String?
}

struct Cargo {
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

struct Shipment {
    let cargoTrack: String
    let pointName: String
    let slot: String
    let status: String
    let employeeFio: String?
    let date: Date
}

struct Report {
    let period: Date
    let income: Double
    let count: Int
    let avgPrice: Double
    let cargoType: String
}

struct WarehouseLoad {
    let pointName: String
    let occupiedSlots: Int
}
