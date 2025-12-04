import Foundation
import PostgresClientKit

class NetworkManager {
    static let shared = NetworkManager()
    private var connection: Connection?
    
    private func ensureConnection() async throws -> Connection {
        if let conn = connection {
            do {
                _ = try conn.prepareStatement(text: "SELECT 1")
                print("Connection test passed!")
                return conn
            } catch {
                print("Connection test failed: \(error.localizedDescription) - full: \(error) - type: \(type(of: error)) - code: \((error as NSError).code)")
                connection = nil
            }
        }
        try await connect()
        guard let conn = connection else {
            throw NSError(domain: "ConnectionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to connect to database"])
        }
        do {
            _ = try conn.prepareStatement(text: "SELECT 1")
            print("Reconnect test passed!")
            return conn
        } catch {
            print("Reconnect test failed: \(error.localizedDescription) - full: \(error) - type: \(type(of: error)) - code: \((error as NSError).code)")
            throw NSError(domain: "ConnectionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test query failed after reconnect"])
        }
    }

    func connect() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                var config = PostgresClientKit.ConnectionConfiguration()
                config.host = "172.20.10.2"
                config.port = 5432
                config.user = "dagosh"
                config.database = "logitrans_golikov_a_08"
                config.credential = .scramSHA256(password: "1008")
                config.ssl = false
                
                print("Attempting connection with config: host=\(config.host), ssl=\(config.ssl)")
                
                self.connection = try Connection(configuration: config)
                print("Connected successfully!")
                continuation.resume()
            } catch {
                print("Connect error: \(error.localizedDescription) - full: \(error) - type: \(type(of: error)) - code: \((error as NSError).code)")
                continuation.resume(throwing: error)
            }
        }
    }

    func login(phone: String, password: String) async throws -> (position: String?, fio: String?) {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "SELECT position, employee_fio FROM Employee WHERE phone = $1 AND password = $2")
                    let cursor = try stmt.execute(parameterValues: [phone, password])
                    defer { cursor.close() }
                    var position: String? = nil
                    var fio: String? = nil
                    for tryRow in cursor {
                        let row = try tryRow.get()
                        position = try row.columns[0].string()
                        fio = try row.columns[1].string()
                        break
                    }
                    continuation.resume(returning: (position, fio))
                } catch {
                    print("Login error: \(error.localizedDescription) - full: \(error) - code: \((error as NSError).code)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func clientLogin(phone: String, password: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "SELECT 1 FROM Client WHERE client_phone = $1 AND password = $2")
                    let cursor = try stmt.execute(parameterValues: [phone, password])
                    defer { cursor.close() }
                    var exists = false
                    for tryRow in cursor {
                        exists = true
                        break
                    }
                    continuation.resume(returning: exists)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getPoints() async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "SELECT point_name FROM Point ORDER BY point_name")
                    let cursor = try stmt.execute()
                    defer { cursor.close() }
                    var points: [String] = []
                    for tryRow in cursor {
                        let row = try tryRow.get()
                        points.append(try row.columns[0].string())
                    }
                    print("Fetched \(points.count) points")
                    continuation.resume(returning: points)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getCargoStatus(track: String) async throws -> [Shipment] {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "SELECT * FROM v_cargo_status WHERE cargo_track = $1")
                    let cursor = try stmt.execute(parameterValues: [track])
                    defer { cursor.close() }
                    var statuses: [Shipment] = []
                    for tryRow in cursor {
                        let row = try tryRow.get()
                        let columns = row.columns
                        let cargoTrack = try columns[0].string()
                        let pointName = try columns[1].string()
                        let status = try columns[2].string()
                        let postgresDate = try columns[3].date()
                        let date = postgresDate.date(in: .current)
                        statuses.append(Shipment(cargoTrack: cargoTrack, pointName: pointName, slot: "", status: status, employeeFio: nil, date: date))
                    }
                    continuation.resume(returning: statuses)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func calculatePrice(mass: Double?, type: String, delivery: String, pack: Bool, ins: Bool) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "SELECT calculate_total_price($1, $2, $3, $4, $5)")
                    let cursor = try stmt.execute(parameterValues: [mass ?? 0, type, delivery, pack, ins])
                    defer { cursor.close() }
                    var price = 0.0
                    for tryRow in cursor {
                        let row = try tryRow.get()
                        price = try row.columns[0].double()
                        break
                    }
                    continuation.resume(returning: price)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getWarehouseLoad() async throws -> [WarehouseLoad] {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "SELECT * FROM v_warehouse_load")
                    let cursor = try stmt.execute()
                    defer { cursor.close() }
                    var loads: [WarehouseLoad] = []
                    for tryRow in cursor {
                        let row = try tryRow.get()
                        let columns = row.columns
                        let pointName = try columns[0].string()
                        let occupiedSlots = try columns[1].int()
                        loads.append(WarehouseLoad(pointName: pointName, occupiedSlots: occupiedSlots))
                    }
                    print("Fetched \(loads.count) warehouse loads")
                    continuation.resume(returning: loads)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getReports() async throws -> [Report] {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "SELECT * FROM v_reports_income")
                    let cursor = try stmt.execute()
                    defer { cursor.close() }
                    var reports: [Report] = []
                    for tryRow in cursor {
                        let row = try tryRow.get()
                        let columns = row.columns
                        let period = try columns[0].date().date(in: .current)
                        let income = try columns[1].double()
                        let count = try columns[2].int()
                        let avgPrice = try columns[3].double()
                        let cargoType = try columns[4].string()
                        reports.append(Report(period: period, income: income, count: count, avgPrice: avgPrice, cargoType: cargoType))
                    }
                    continuation.resume(returning: reports)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getShipments(by point: String) async throws -> [Shipment] {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "SELECT * FROM get_shipments_by_point($1)")
                    let cursor = try stmt.execute(parameterValues: [point])
                    defer { cursor.close() }
                    var shipments: [Shipment] = []
                    for tryRow in cursor {
                        let row = try tryRow.get()
                        let columns = row.columns
                        let cargoTrack = try columns[0].string()
                        let pointName = try columns[1].string()
                        let slot = try columns[2].string()
                        let status = try columns[3].string()
                        let employeeFio = try? columns[4].string()
                        let date = try columns[5].date().date(in: .current)
                        shipments.append(Shipment(cargoTrack: cargoTrack, pointName: pointName, slot: slot, status: status, employeeFio: employeeFio, date: date))
                    }
                    print("Fetched \(shipments.count) shipments for point: \(point)")
                    continuation.resume(returning: shipments)
                } catch {
                    print("Error fetching shipments for point \(point): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func insertCargo(track: String, type: String, delivery: String, sender: String, receiver: String, price: Double, mass: Double?, value: Double?, pack: Bool, ins: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_insert_cargo($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)")
                    let cursor = try stmt.execute(parameterValues: [track, type, delivery, sender, receiver, price, mass, value, pack, ins])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func updateCargo(track: String, newType: String, newDelivery: String, newPrice: Double, newMass: Double, newValue: Double, newPack: Bool, newIns: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_update_cargo($1, $2, $3, $4, $5, $6, $7, $8)")
                    let cursor = try stmt.execute(parameterValues: [track, newType, newDelivery, newMass, newValue, newPrice, newPack, newIns])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteCargo(track: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_delete_cargo($1)")
                    let cursor = try stmt.execute(parameterValues: [track])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func insertShipment(cargoTrack: String, pointName: String, slot: String, status: String, employeeFio: String, date: Date) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_insert_shipment($1, $2, $3, $4, $5, $6)")
                    let postgresDate = PostgresDate(date: date, in: .current)
                    let cursor = try stmt.execute(parameterValues: [cargoTrack, pointName, slot, status, employeeFio, postgresDate])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func updateShipment(cargoTrack: String, pointName: String, newSlot: String, newStatus: String, newEmployeeFio: String, newDate: Date) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_update_shipment($1, $2, $3, $4, $5, $6)")
                    let postgresDate = PostgresDate(date: newDate, in: .current)
                    let cursor = try stmt.execute(parameterValues: [cargoTrack, pointName, newSlot, newStatus, newEmployeeFio, postgresDate])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteShipment(cargoTrack: String, pointName: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_delete_shipment($1, $2)")
                    let cursor = try stmt.execute(parameterValues: [cargoTrack, pointName])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func archiveShipment(cargoTrack: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_archive_shipment($1)")
                    let cursor = try stmt.execute(parameterValues: [cargoTrack])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func insertClient(phone: String, address: String, fio: String, password: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_insert_client($1, $2, $3, $4)")
                    let cursor = try stmt.execute(parameterValues: [phone, address, fio, password])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func updateClient(phone: String, newAddress: String, newFio: String, newPassword: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_update_client($1, $2, $3, $4)")
                    let cursor = try stmt.execute(parameterValues: [phone, newAddress, newFio, newPassword])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteClient(phone: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_delete_client($1)")
                    let cursor = try stmt.execute(parameterValues: [phone])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func insertPoint(name: String, phone: String, address: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_insert_point($1, $2, $3)")
                    let cursor = try stmt.execute(parameterValues: [name, phone, address])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func updatePoint(name: String, newPhone: String, newAddress: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_update_point($1, $2, $3)")
                    let cursor = try stmt.execute(parameterValues: [name, newPhone, newAddress])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deletePoint(name: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_delete_point($1)")
                    let cursor = try stmt.execute(parameterValues: [name])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func insertEmployee(fio: String, position: String, phone: String, password: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_insert_employee($1, $2, $3, $4)")
                    let cursor = try stmt.execute(parameterValues: [fio, position, phone, password])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func updateEmployee(fio: String, newPosition: String, newPhone: String, newPassword: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_update_employee($1, $2, $3, $4)")
                    let cursor = try stmt.execute(parameterValues: [fio, newPosition, newPhone, newPassword])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteEmployee(fio: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let conn = try await ensureConnection()
                    let stmt = try conn.prepareStatement(text: "CALL proc_delete_employee($1)")
                    let cursor = try stmt.execute(parameterValues: [fio])
                    defer { cursor.close() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
