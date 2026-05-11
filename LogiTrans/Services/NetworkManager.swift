import Foundation
import PostgresClientKit

enum AppError: LocalizedError {
    case notConfigured
    case connectionFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Настройте подключение к БД в Настройках (⚙)"
        case .connectionFailed: return "Не удалось подключиться к базе данных"
        }
    }
}

actor NetworkManager {
    static let shared = NetworkManager()
    private var connection: Connection?

    private func ensureConnection() throws -> Connection {
        if let conn = connection, (try? conn.prepareStatement(text: "SELECT 1")) != nil {
            return conn
        }
        connection = nil
        return try createConnection()
    }

    private func createConnection() throws -> Connection {
        guard AppConfig.isConfigured else { throw AppError.notConfigured }
        var cfg = PostgresClientKit.ConnectionConfiguration()
        cfg.host = AppConfig.dbHost
        cfg.port = AppConfig.dbPort
        cfg.user = AppConfig.dbUser
        cfg.database = AppConfig.dbName
        cfg.credential = .scramSHA256(password: AppConfig.dbPassword)
        cfg.ssl = false
        cfg.socketTimeout = 10
        print("[DB] createConnection → tcp \(cfg.host):\(cfg.port) user=\(cfg.user) db=\(cfg.database) ssl=\(cfg.ssl) timeout=\(cfg.socketTimeout)s")
        do {
            let conn = try Connection(configuration: cfg)
            connection = conn
            print("[DB] createConnection → TCP соединение установлено")
            return conn
        } catch let e as PostgresError {
            print("[DB] createConnection → PostgresError: \(e)")
            throw e
        } catch {
            print("[DB] createConnection → системная ошибка: \(error) (код \((error as NSError).code), домен \((error as NSError).domain))")
            throw error
        }
    }

    func resetConnection() {
        connection = nil
    }

    func testConnection() async throws {
        print("[DB] testConnection → начало, host=\(AppConfig.dbHost):\(AppConfig.dbPort)")
        let conn = try createConnection()
        print("[DB] testConnection → выполняем SELECT 1")
        do {
            let stmt = try conn.prepareStatement(text: "SELECT 1")
            let cursor = try stmt.execute()
            cursor.close()
            print("[DB] testConnection → успешно, сервер отвечает")
        } catch {
            print("[DB] testConnection → SELECT 1 упал: \(error)")
            throw error
        }
    }

    // MARK: - Auth

    func login(phone: String, password: String) async throws -> (position: String?, fio: String?) {
        print("[DB] login → host=\(AppConfig.dbHost):\(AppConfig.dbPort) db=\(AppConfig.dbName) user=\(AppConfig.dbUser)")
        let conn = try ensureConnection()
        print("[DB] login → соединение установлено, выполняем запрос")
        let stmt = try conn.prepareStatement(text: "SELECT position, employee_fio FROM Employee WHERE phone = $1 AND password = $2")
        let cursor = try stmt.execute(parameterValues: [phone, password])
        defer { cursor.close() }
        for tryRow in cursor {
            let row = try tryRow.get()
            let pos = try row.columns[0].string()
            let fio = try row.columns[1].string()
            print("[DB] login → найден сотрудник: \(fio), роль: \(pos)")
            return (pos, fio)
        }
        print("[DB] login → сотрудник не найден")
        return (nil, nil)
    }

    func clientLogin(phone: String, password: String) async throws -> Bool {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "SELECT 1 FROM Client WHERE client_phone = $1 AND password = $2")
        let cursor = try stmt.execute(parameterValues: [phone, password])
        defer { cursor.close() }
        for _ in cursor { return true }
        return false
    }

    // MARK: - Points

    func getPoints() async throws -> [String] {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "SELECT point_name FROM Point ORDER BY point_name")
        let cursor = try stmt.execute()
        defer { cursor.close() }
        var points: [String] = []
        for tryRow in cursor {
            let row = try tryRow.get()
            points.append(try row.columns[0].string())
        }
        return points
    }

    // MARK: - Cargo

    func getCargoStatus(track: String) async throws -> [Shipment] {
        // v_cargo_status columns: [0]cargo_track [1]point_name [2]slot [3]status [4]employee_fio [5]update_date
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "SELECT * FROM v_cargo_status WHERE cargo_track = $1")
        let cursor = try stmt.execute(parameterValues: [track])
        defer { cursor.close() }
        var statuses: [Shipment] = []
        for tryRow in cursor {
            let row = try tryRow.get()
            let cols = row.columns
            statuses.append(Shipment(
                cargoTrack:  try  cols[0].string(),
                pointName:   try  cols[1].string(),
                slot:        (try? cols[2].string()) ?? "",
                status:      try  cols[3].string(),
                employeeFio: try? cols[4].string(),
                date:        try  cols[5].date().date(in: .current)
            ))
        }
        return statuses
    }

    func calculatePrice(mass: Double?, type: String, delivery: String, pack: Bool, ins: Bool) async throws -> Double {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "SELECT calculate_total_price($1, $2, $3, $4, $5)")
        let cursor = try stmt.execute(parameterValues: [mass ?? 0, type, delivery, pack, ins])
        defer { cursor.close() }
        for tryRow in cursor {
            let row = try tryRow.get()
            return try row.columns[0].double()
        }
        return 0
    }

    func insertCargo(track: String, type: String, delivery: String, sender: String, receiver: String,
                     price: Double, mass: Double?, value: Double?, pack: Bool, ins: Bool) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_insert_cargo($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)")
        let cursor = try stmt.execute(parameterValues: [track, type, delivery, sender, receiver, price, mass, value, pack, ins])
        cursor.close()
    }

    func updateCargo(track: String, newType: String, newDelivery: String, newPrice: Double,
                     newMass: Double, newValue: Double, newPack: Bool, newIns: Bool) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_update_cargo($1, $2, $3, $4, $5, $6, $7, $8)")
        let cursor = try stmt.execute(parameterValues: [track, newType, newDelivery, newMass, newValue, newPrice, newPack, newIns])
        cursor.close()
    }

    func deleteCargo(track: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_delete_cargo($1)")
        let cursor = try stmt.execute(parameterValues: [track])
        cursor.close()
    }

    // MARK: - Shipments

    func getShipments(by point: String) async throws -> [Shipment] {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "SELECT * FROM get_shipments_by_point($1)")
        let cursor = try stmt.execute(parameterValues: [point])
        defer { cursor.close() }
        var shipments: [Shipment] = []
        for tryRow in cursor {
            let row = try tryRow.get()
            let cols = row.columns
            shipments.append(Shipment(
                cargoTrack: try cols[0].string(),
                pointName: try cols[1].string(),
                slot: try cols[2].string(),
                status: try cols[3].string(),
                employeeFio: try? cols[4].string(),
                date: try cols[5].date().date(in: .current)
            ))
        }
        return shipments
    }

    func insertShipment(cargoTrack: String, pointName: String, slot: String, status: String,
                        employeeFio: String, date: Date) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_insert_shipment($1, $2, $3, $4, $5, $6)")
        let cursor = try stmt.execute(parameterValues: [cargoTrack, pointName, slot, status, employeeFio, PostgresDate(date: date, in: .current)])
        cursor.close()
    }

    func updateShipment(cargoTrack: String, pointName: String, newSlot: String, newStatus: String,
                        newEmployeeFio: String, newDate: Date) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_update_shipment($1, $2, $3, $4, $5, $6)")
        let cursor = try stmt.execute(parameterValues: [cargoTrack, pointName, newSlot, newStatus, newEmployeeFio, PostgresDate(date: newDate, in: .current)])
        cursor.close()
    }

    func deleteShipment(cargoTrack: String, pointName: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_delete_shipment($1, $2)")
        let cursor = try stmt.execute(parameterValues: [cargoTrack, pointName])
        cursor.close()
    }

    func archiveShipment(cargoTrack: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_archive_shipment($1)")
        let cursor = try stmt.execute(parameterValues: [cargoTrack])
        cursor.close()
    }

    // MARK: - Warehouse & Reports

    func getWarehouseLoad() async throws -> [WarehouseLoad] {
        // Casting bigint → integer so PostgresClientKit can read with .int()
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: """
            SELECT point_name,
                   occupied_slots::integer
            FROM v_warehouse_load
            ORDER BY point_name
            """)
        let cursor = try stmt.execute()
        defer { cursor.close() }
        var loads: [WarehouseLoad] = []
        for tryRow in cursor {
            let row = try tryRow.get()
            let cols = row.columns
            loads.append(WarehouseLoad(
                pointName:     try cols[0].string(),
                occupiedSlots: try cols[1].int()
            ))
        }
        return loads
    }

    func getReports() async throws -> [Report] {
        // Casting timestamptz → date and bigint → integer for correct Swift type mapping
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: """
            SELECT period::date,
                   income,
                   shipments_count::integer,
                   avg_price,
                   cargo_type
            FROM v_reports_income
            ORDER BY period DESC, cargo_type
            """)
        let cursor = try stmt.execute()
        defer { cursor.close() }
        var reports: [Report] = []
        for tryRow in cursor {
            let row = try tryRow.get()
            let cols = row.columns
            reports.append(Report(
                period:     try cols[0].date().date(in: .current),
                income:     try cols[1].double(),
                count:      try cols[2].int(),
                avgPrice:   try cols[3].double(),
                cargoType:  try cols[4].string()
            ))
        }
        return reports
    }

    // MARK: - Clients

    func getClients() async throws -> [Client] {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "SELECT client_phone, address, fio, password FROM Client ORDER BY fio")
        let cursor = try stmt.execute()
        defer { cursor.close() }
        var clients: [Client] = []
        for tryRow in cursor {
            let row = try tryRow.get()
            clients.append(Client(
                phone: try row.columns[0].string(),
                address: try? row.columns[1].string(),
                fio: try row.columns[2].string(),
                password: try? row.columns[3].string()
            ))
        }
        return clients
    }

    func getCargoByClient(phone: String) async throws -> [Cargo] {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: """
            SELECT cargo_track, cargo_type, delivery_type,
                   sender_phone, receiver_phone,
                   total_price, cargo_mass, cargo_value, packaging, insurance
            FROM Cargo
            WHERE sender_phone = $1 OR receiver_phone = $1
            ORDER BY cargo_track
            """)
        let cursor = try stmt.execute(parameterValues: [phone])
        defer { cursor.close() }
        var cargos: [Cargo] = []
        for tryRow in cursor {
            let row = try tryRow.get()
            let cols = row.columns
            cargos.append(Cargo(
                track:        try  cols[0].string(),
                type:         try  cols[1].string(),
                delivery:     try  cols[2].string(),
                senderPhone:  (try? cols[3].string()) ?? "",
                receiverPhone:(try? cols[4].string()) ?? "",
                price:        (try? cols[5].double()) ?? 0,
                mass:         try? cols[6].double(),
                value:        try? cols[7].double(),
                packaging:    (try? cols[8].bool())   ?? false,
                insurance:    (try? cols[9].bool())   ?? false
            ))
        }
        return cargos
    }

    func insertClient(phone: String, address: String, fio: String, password: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_insert_client($1, $2, $3, $4)")
        let cursor = try stmt.execute(parameterValues: [phone, address, fio, password])
        cursor.close()
    }

    func updateClient(phone: String, newAddress: String, newFio: String, newPassword: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_update_client($1, $2, $3, $4)")
        let cursor = try stmt.execute(parameterValues: [phone, newAddress, newFio, newPassword])
        cursor.close()
    }

    func deleteClient(phone: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_delete_client($1)")
        let cursor = try stmt.execute(parameterValues: [phone])
        cursor.close()
    }

    // MARK: - Points CRUD

    func insertPoint(name: String, phone: String, address: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_insert_point($1, $2, $3)")
        let cursor = try stmt.execute(parameterValues: [name, phone, address])
        cursor.close()
    }

    func updatePoint(name: String, newPhone: String, newAddress: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_update_point($1, $2, $3)")
        let cursor = try stmt.execute(parameterValues: [name, newPhone, newAddress])
        cursor.close()
    }

    func deletePoint(name: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_delete_point($1)")
        let cursor = try stmt.execute(parameterValues: [name])
        cursor.close()
    }

    // MARK: - Employees

    func insertEmployee(fio: String, position: String, phone: String, password: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_insert_employee($1, $2, $3, $4)")
        let cursor = try stmt.execute(parameterValues: [fio, position, phone, password])
        cursor.close()
    }

    func updateEmployee(fio: String, newPosition: String, newPhone: String, newPassword: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_update_employee($1, $2, $3, $4)")
        let cursor = try stmt.execute(parameterValues: [fio, newPosition, newPhone, newPassword])
        cursor.close()
    }

    func deleteEmployee(fio: String) async throws {
        let conn = try ensureConnection()
        let stmt = try conn.prepareStatement(text: "CALL proc_delete_employee($1)")
        let cursor = try stmt.execute(parameterValues: [fio])
        cursor.close()
    }
}
