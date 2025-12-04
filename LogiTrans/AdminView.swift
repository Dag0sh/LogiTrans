import SwiftUI

struct AdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var cargoTrack = ""
    @State private var newCargoType = ""
    @State private var newDelivery = ""
    @State private var newPrice: Double? = nil
    @State private var newMass: Double? = nil
    @State private var newValue: Double? = nil
    @State private var newPack = false
    @State private var newIns = false
    @State private var clientPhone = ""
    @State private var newClientAddress = ""
    @State private var newClientFio = ""
    @State private var newClientPassword = ""
    @State private var pointName = ""
    @State private var newPointPhone = ""
    @State private var newPointAddress = ""
    @State private var employeeFio = ""
    @State private var newEmployeePosition = ""
    @State private var newEmployeePhone = ""
    @State private var newEmployeePassword = ""
    @State private var error: String?
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case cargoTrack, newCargoType, newDelivery, newPrice, newMass, newValue,
             clientPhone, newClientAddress, newClientFio, newClientPassword,
             pointName, newPointPhone, newPointAddress,
             employeeFio, newEmployeePosition, newEmployeePhone, newEmployeePassword
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Администрирование")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.gray)
                        Divider().background(Color(.systemGray3))
                    }
                    .padding(.top, 8)

                    Picker("Сущность", selection: $selectedTab) {
                        Text("Грузы").tag(0)
                        Text("Клиенты").tag(1)
                        Text("Пункты").tag(2)
                        Text("Сотрудники").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    Group {
                        switch selectedTab {
                        case 0: cargoManagementView
                        case 1: clientManagementView
                        case 2: pointManagementView
                        default: employeeManagementView
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    .transition(.opacity)

                    if let err = error {
                        Text(err)
                            .foregroundColor(err.contains("!") ? .green : .red)
                            .font(.callout)
                            .padding(.top, 8)
                            .transition(.opacity)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(.keyboard)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
    }

    private func adminField(_ placeholder: String, text: Binding<String>, isSecure: Bool = false, keyboard: UIKeyboardType = .default, focus: Field? = nil) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .padding(10)
                    .focused($focusedField, equals: focus)
            } else {
                TextField(placeholder, text: text)
                    .padding(10)
                    .keyboardType(keyboard)
                    .focused($focusedField, equals: focus)
            }
        }
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }

    private func adminNumField(_ placeholder: String, value: Binding<Double?>, focus: Field? = nil) -> some View {
        TextField(placeholder, value: value, formatter: NumberFormatter())
            .padding(10)
            .keyboardType(.decimalPad)
            .background(Color(.systemGray5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.vertical, 4)
            .focused($focusedField, equals: focus)
    }

    private func adminToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .padding(10)
            .background(Color(.systemGray5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.vertical, 4)
    }

    private func adminButton(_ title: String, color: Color, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(8)
        }
        .background(color.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
    }

    private var cargoManagementView: some View {
        VStack(spacing: 8) {
            adminField("Трек груза", text: $cargoTrack, focus: .cargoTrack)
            adminField("Новый тип", text: $newCargoType, focus: .newCargoType)
            adminField("Новая доставка", text: $newDelivery, focus: .newDelivery)
            adminNumField("Новая цена", value: $newPrice, focus: .newPrice)
            adminNumField("Новая масса", value: $newMass, focus: .newMass)
            adminNumField("Новое значение", value: $newValue, focus: .newValue)
            adminToggle("Упаковка", isOn: $newPack)
            adminToggle("Страховка", isOn: $newIns)
            HStack(spacing: 8) {
                adminButton("Создать груз", color: .blue, systemImage: "plus") {
                    Task {
                        do {
                            let calculatedPrice = try await NetworkManager.shared.calculatePrice(mass: newMass, type: newCargoType, delivery: newDelivery, pack: newPack, ins: newIns)
                            try await NetworkManager.shared.insertCargo(track: cargoTrack, type: newCargoType, delivery: newDelivery, sender: "", receiver: "", price: calculatedPrice, mass: newMass, value: newValue, pack: newPack, ins: newIns)
                            error = "Создано!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
                adminButton("Обновить груз", color: .blue, systemImage: "arrow.clockwise") {
                    Task {
                        do {
                            try await NetworkManager.shared.updateCargo(track: cargoTrack, newType: newCargoType, newDelivery: newDelivery, newPrice: newPrice ?? 0, newMass: newMass ?? 0, newValue: newValue ?? 0, newPack: newPack, newIns: newIns)
                            error = "Обновлено!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
                adminButton("Удалить груз", color: .red, systemImage: "trash") {
                    Task {
                        do {
                            try await NetworkManager.shared.deleteCargo(track: cargoTrack)
                            error = "Удалено!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
            }.padding(.top, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }

    private var clientManagementView: some View {
        VStack(spacing: 8) {
            adminField("Телефон клиента", text: $clientPhone, keyboard: .phonePad, focus: .clientPhone)
            adminField("Новый адрес", text: $newClientAddress, focus: .newClientAddress)
            adminField("Новое ФИО", text: $newClientFio, focus: .newClientFio)
            adminField("Новый пароль", text: $newClientPassword, isSecure: true, focus: .newClientPassword)
            HStack(spacing: 8) {
                adminButton("Создать клиента", color: .blue, systemImage: "person.crop.circle.badge.plus") {
                    Task {
                        do {
                            try await NetworkManager.shared.insertClient(phone: clientPhone, address: newClientAddress, fio: newClientFio, password: newClientPassword)
                            error = "Создано!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
                adminButton("Обновить клиента", color: .blue, systemImage: "arrow.clockwise") {
                    Task {
                        do {
                            try await NetworkManager.shared.updateClient(phone: clientPhone, newAddress: newClientAddress, newFio: newClientFio, newPassword: newClientPassword)
                            error = "Обновлено!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
                adminButton("Удалить клиента", color: .red, systemImage: "trash") {
                    Task {
                        do {
                            try await NetworkManager.shared.deleteClient(phone: clientPhone)
                            error = "Удалено!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
            }.padding(.top, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }

    private var pointManagementView: some View {
        VStack(spacing: 8) {
            adminField("Название пункта", text: $pointName, focus: .pointName)
            adminField("Новый телефон", text: $newPointPhone, keyboard: .phonePad, focus: .newPointPhone)
            adminField("Новый адрес", text: $newPointAddress, focus: .newPointAddress)
            HStack(spacing: 8) {
                adminButton("Создать пункт", color: .blue, systemImage: "plus") {
                    Task {
                        do {
                            try await NetworkManager.shared.insertPoint(name: pointName, phone: newPointPhone, address: newPointAddress)
                            error = "Создано!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
                adminButton("Обновить пункт", color: .blue, systemImage: "arrow.clockwise") {
                    Task {
                        do {
                            try await NetworkManager.shared.updatePoint(name: pointName, newPhone: newPointPhone, newAddress: newPointAddress)
                            error = "Обновлено!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
                adminButton("Удалить пункт", color: .red, systemImage: "trash") {
                    Task {
                        do {
                            try await NetworkManager.shared.deletePoint(name: pointName)
                            error = "Удалено!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
            }.padding(.top, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }

    private var employeeManagementView: some View {
        VStack(spacing: 8) {
            adminField("ФИО сотрудника", text: $employeeFio, focus: .employeeFio)
            Picker("Новая позиция", selection: $newEmployeePosition) {
                Text("Руководитель").tag("Руководитель")
                Text("Администратор").tag("Администратор")
                Text("Оператор").tag("Оператор")
                Text("Работник склада").tag("Работник склада")
                Text("Менеджер").tag("Менеджер")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 2)
            adminField("Новый телефон", text: $newEmployeePhone, keyboard: .phonePad, focus: .newEmployeePhone)
            adminField("Новый пароль", text: $newEmployeePassword, isSecure: true, focus: .newEmployeePassword)
            HStack(spacing: 8) {
                adminButton("Создать сотрудника", color: .blue, systemImage: "person.crop.circle.badge.plus") {
                    Task {
                        do {
                            try await NetworkManager.shared.insertEmployee(fio: employeeFio, position: newEmployeePosition, phone: newEmployeePhone, password: newEmployeePassword)
                            error = "Создано!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
                adminButton("Обновить сотрудника", color: .blue, systemImage: "arrow.clockwise") {
                    Task {
                        do {
                            try await NetworkManager.shared.updateEmployee(fio: employeeFio, newPosition: newEmployeePosition, newPhone: newEmployeePhone, newPassword: newEmployeePassword)
                            error = "Обновлено!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
                adminButton("Удалить сотрудника", color: .red, systemImage: "trash") {
                    Task {
                        do {
                            try await NetworkManager.shared.deleteEmployee(fio: employeeFio)
                            error = "Удалено!"
                        } catch let err {
                            error = err.localizedDescription
                        }
                    }
                }
            }.padding(.top, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
        .onAppear {
            if newEmployeePosition.isEmpty {
                newEmployeePosition = "Оператор"
            }
        }
    }
}
