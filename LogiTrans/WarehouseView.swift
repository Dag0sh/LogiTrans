import SwiftUI

struct WarehouseView: View {
    @State private var point = ""
    @State private var shipments: [Shipment] = []
    @State private var selectedTrack = ""
    @State private var newSlot = ""
    @State private var newStatus = ""
    @State private var newEmployeeFio = ""
    @State private var error: String?
    @State private var showingEditSheet = false
    @State private var goToLogin = false
    @State private var points: [String] = []

    @Environment(\.dismiss) private var dismiss

    var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color(.black).opacity(0.05), radius: 1.5, x: 0, y: 1)
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            if goToLogin {
                LoginView()
            } else {
                ScrollView {
                    VStack(spacing: 26) {
                        VStack(spacing: 10) {
                            Text("Склад: учёт отгрузок")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.gray)
                            Divider()
                                .background(Color(.systemGray3))
                        }
                        .padding(.top, 20)
                        VStack(spacing: 14) {
                            Picker("Пункт", selection: $point) {
                                if points.isEmpty {
                                    Text("Нет доступных пунктов").tag("")
                                } else {
                                    ForEach(points, id: \.self) { pointName in
                                        Text(pointName).tag(pointName)
                                    }
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(fieldBackground)
                            .padding(.horizontal, 2)
                            .disabled(points.isEmpty)
                            Button(action: {
                                Task {
                                    do {
                                        shipments = try await NetworkManager.shared.getShipments(by: point)
                                        error = nil
                                    } catch let err {
                                        error = err.localizedDescription
                                    }
                                }
                            }) {
                                Text("Получить отгрузки")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(point.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        if !shipments.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Текущие отгрузки:")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 4)
                                ForEach(shipments, id: \.cargoTrack) { shipment in
                                    VStack(alignment: .leading, spacing: 7) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Груз: \(shipment.cargoTrack)").font(.system(size: 16, weight: .medium))
                                                Text("Слот: \(shipment.slot)")
                                                    .foregroundColor(.secondary)
                                                Text("Статус: \(shipment.status)")
                                                    .foregroundColor(.secondary)
                                                if let fio = shipment.employeeFio, !fio.isEmpty {
                                                    Text("Сотрудник: \(fio)")
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                            Button(action: {
                                                selectedTrack = shipment.cargoTrack
                                                newSlot = shipment.slot
                                                newStatus = shipment.status.lowercased()
                                                newEmployeeFio = shipment.employeeFio ?? ""
                                                showingEditSheet = true
                                            }) {
                                                Image(systemName: "square.and.pencil")
                                                    .foregroundColor(.blue)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding()
                                    .background(fieldBackground)
                                    .padding(.bottom, 2)
                                }
                            }
                            .padding(.horizontal, 2)
                            .transition(.opacity)
                        }
                        if let err = error {
                            Text(err)
                                .foregroundColor(.red)
                                .padding(.top, 6)
                        }
                        Spacer(minLength: 14)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditShipmentSheet(
                        track: $selectedTrack,
                        point: $point,
                        newSlot: $newSlot,
                        newStatus: $newStatus,
                        newEmployeeFio: $newEmployeeFio,
                        isShown: $showingEditSheet,
                        onUpdate: { track, slot, status, fio in
                            Task {
                                do {
                                    try await NetworkManager.shared.updateShipment(cargoTrack: track, pointName: point, newSlot: slot, newStatus: status, newEmployeeFio: fio, newDate: Date())
                                    if status == "доставлено" {
                                        try await NetworkManager.shared.archiveShipment(cargoTrack: track)
                                    }
                                    error = "Обновлено!"
                                    shipments = try await NetworkManager.shared.getShipments(by: point)
                                } catch let err{
                                    error = err.localizedDescription
                                }
                            }
                        }
                    )
                    .background(Color(.systemGray6))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
        .onAppear {
            Task {
                do {
                    points = try await NetworkManager.shared.getPoints()
                    if points.isEmpty {
                        error = "Нет доступных пунктов в БД"
                    } else if point.isEmpty && !points.isEmpty {
                        point = points[0]
                    }
                } catch let err {
                    error = err.localizedDescription
                }
            }
        }
    }
}

struct EditShipmentSheet: View {
    @Binding var track: String
    @Binding var point: String
    @Binding var newSlot: String
    @Binding var newStatus: String
    @Binding var newEmployeeFio: String
    @Binding var isShown: Bool

    @State private var nextPoint = ""
    @State private var points: [String] = []
    @State private var statusOptions = ["занято", "в пути", "доставлено"]

    var onUpdate: (_ track: String, _ slot: String, _ status: String, _ fio: String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Text("Редактировать отгрузку")
                        .font(.title3.bold())
                        .foregroundColor(.gray)
                    Text("Трек: \(track)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Group {
                    TextField("Новый слот", text: $newSlot)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(Color.white)
                        )
                    Picker("Новый статус", selection: $newStatus) {
                        ForEach(statusOptions, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10).fill(Color.white)
                    )
                    TextField("Новое ФИО сотрудника", text: $newEmployeeFio)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(Color.white)
                        )
                    if newStatus == "в пути" {
                        Picker("Следующий пункт", selection: $nextPoint) {
                            ForEach(points, id: \.self) { pointName in
                                Text(pointName).tag(pointName)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(Color.white)
                        )
                    }
                }
                .font(.system(size: 16))
                Button(action: {
                    isShown = false
                    onUpdate(track, newSlot, newStatus, newEmployeeFio)
                }) {
                    Text("Обновить отгрузку")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(newSlot.trimmingCharacters(in: .whitespaces).isEmpty || newStatus.trimmingCharacters(in: .whitespaces).isEmpty)
                Spacer()
            }
            .padding(22)
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationBarItems(leading: Button("Закрыть") {
                isShown = false
            })
            .onAppear {
                Task {
                    newStatus = newStatus.lowercased()
                    do {
                        points = try await NetworkManager.shared.getPoints()
                    } catch {
                    }
                }
            }
        }
    }
}
