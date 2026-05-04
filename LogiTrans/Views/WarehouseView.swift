import SwiftUI

struct WarehouseView: View {
    @StateObject private var vm = WarehouseViewModel()
    @State private var showingEditSheet = false
    @State private var selectedShipment: Shipment?
    @Environment(\.dismiss) private var dismiss

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color(.black).opacity(0.05), radius: 1.5, x: 0, y: 1)
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 26) {
                    VStack(spacing: 10) {
                        Text("Склад: учёт отгрузок")
                            .font(.system(size: 26, weight: .bold)).foregroundColor(.gray)
                        Divider().background(Color(.systemGray3))
                    }
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        Picker("Пункт", selection: $vm.point) {
                            if vm.points.isEmpty {
                                Text("Нет доступных пунктов").tag("")
                            } else {
                                ForEach(vm.points, id: \.self) { Text($0).tag($0) }
                            }
                        }
                        .pickerStyle(MenuPickerStyle()).padding().background(fieldBackground)
                        .disabled(vm.points.isEmpty)

                        Button {
                            Task { await vm.loadShipments() }
                        } label: {
                            Text("Получить отгрузки")
                                .font(.system(size: 17, weight: .semibold)).frame(maxWidth: .infinity)
                        }
                        .padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)
                        .disabled(vm.point.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if !vm.shipments.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Текущие отгрузки:")
                                .font(.system(size: 19, weight: .semibold)).foregroundColor(.gray)
                            ForEach(vm.shipments) { shipment in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Груз: \(shipment.cargoTrack)").font(.system(size: 16, weight: .medium))
                                        Text("Слот: \(shipment.slot)").foregroundColor(.secondary)
                                        Text("Статус: \(shipment.status)").foregroundColor(.secondary)
                                        if let fio = shipment.employeeFio, !fio.isEmpty {
                                            Text("Сотрудник: \(fio)").foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        selectedShipment = shipment
                                        showingEditSheet = true
                                    } label: {
                                        Image(systemName: "square.and.pencil").foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding().background(fieldBackground)
                            }
                        }
                    }

                    if let msg = vm.statusMessage {
                        Text(msg).foregroundColor(vm.isError ? .red : .green).padding(.top, 6)
                    }

                    Spacer(minLength: 14)
                }
                .padding(.horizontal, 18).padding(.bottom, 18)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let shipment = selectedShipment {
                    EditShipmentSheet(shipment: shipment) { track, slot, status, fio in
                        Task { await vm.updateShipment(track: track, slot: slot, status: status, fio: fio) }
                    }
                    .background(Color(.systemGray6))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { Button("Закрыть") { dismiss() } }
        }
        .onAppear { Task { await vm.loadPoints() } }
    }
}

struct EditShipmentSheet: View {
    let shipment: Shipment
    let onUpdate: (String, String, String, String) -> Void

    @State private var newSlot: String
    @State private var newStatus: String
    @State private var newEmployeeFio: String
    @State private var points: [String] = []
    @State private var nextPoint = ""
    @Environment(\.dismiss) private var dismiss

    private let statusOptions = ["занято", "в пути", "доставлено"]

    init(shipment: Shipment, onUpdate: @escaping (String, String, String, String) -> Void) {
        self.shipment = shipment
        self.onUpdate = onUpdate
        _newSlot = State(initialValue: shipment.slot)
        _newStatus = State(initialValue: shipment.status.lowercased())
        _newEmployeeFio = State(initialValue: shipment.employeeFio ?? "")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Text("Редактировать отгрузку").font(.title3.bold()).foregroundColor(.gray)
                    Text("Трек: \(shipment.cargoTrack)").font(.system(size: 16, weight: .medium)).foregroundColor(.secondary)
                }
                Group {
                    TextField("Новый слот", text: $newSlot)
                        .padding().background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                    Picker("Новый статус", selection: $newStatus) {
                        ForEach(statusOptions, id: \.self) { Text($0.capitalized).tag($0) }
                    }.pickerStyle(MenuPickerStyle()).padding().background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                    TextField("Новое ФИО сотрудника", text: $newEmployeeFio)
                        .padding().background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                    if newStatus == "в пути" {
                        Picker("Следующий пункт", selection: $nextPoint) {
                            ForEach(points, id: \.self) { Text($0).tag($0) }
                        }.pickerStyle(MenuPickerStyle()).padding().background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                    }
                }
                .font(.system(size: 16))

                Button {
                    dismiss()
                    onUpdate(shipment.cargoTrack, newSlot, newStatus, newEmployeeFio)
                } label: {
                    Text("Обновить отгрузку").font(.system(size: 17, weight: .semibold)).frame(maxWidth: .infinity)
                }
                .padding().background(Color.blue).foregroundColor(.white).cornerRadius(12)
                .disabled(newSlot.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding(22)
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationBarItems(leading: Button("Закрыть") { dismiss() })
            .onAppear {
                Task { points = (try? await NetworkManager.shared.getPoints()) ?? [] }
            }
        }
    }
}
