import SwiftUI

struct AdminView: View {
    @StateObject private var vm = AdminViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case cargoTrack, newCargoType, newDelivery, newPrice, newMass, newValue
        case clientPhone, newClientAddress, newClientFio, newClientPassword
        case pointName, newPointPhone, newPointAddress
        case employeeFio, newEmployeePhone, newEmployeePassword
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Администрирование")
                            .font(.system(size: 32, weight: .bold)).foregroundColor(.gray)
                        Divider().background(Color(.systemGray3))
                    }
                    .padding(.top, 8)

                    Picker("Сущность", selection: $selectedTab) {
                        Text("Грузы").tag(0)
                        Text("Клиенты").tag(1)
                        Text("Пункты").tag(2)
                        Text("Сотрудники").tag(3)
                    }.pickerStyle(SegmentedPickerStyle()).padding(.horizontal)

                    Group {
                        switch selectedTab {
                        case 0: cargoManagementView
                        case 1: clientManagementView
                        case 2: pointManagementView
                        default: employeeManagementView
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)

                    if let msg = vm.statusMessage {
                        Text(msg)
                            .foregroundColor(vm.isError ? .red : .green)
                            .font(.callout).padding(.top, 8)
                    }
                    Spacer()
                }
                .padding(.horizontal).frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(.keyboard)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { Button("Закрыть") { dismiss() } }
        }
    }

    // MARK: - Helpers

    private func adminField(_ placeholder: String, text: Binding<String>, isSecure: Bool = false,
                             keyboard: UIKeyboardType = .default, focus: Field? = nil) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text).padding(10).focused($focusedField, equals: focus)
            } else {
                TextField(placeholder, text: text).padding(10).keyboardType(keyboard).focused($focusedField, equals: focus)
            }
        }
        .background(Color(.systemGray5)).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
        .padding(.vertical, 4)
    }

    private func adminNumField(_ placeholder: String, value: Binding<Double?>, focus: Field? = nil) -> some View {
        TextField(placeholder, value: value, formatter: NumberFormatter())
            .padding(10).keyboardType(.decimalPad)
            .background(Color(.systemGray5)).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
            .padding(.vertical, 4).focused($focusedField, equals: focus)
    }

    private func adminToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .padding(10).background(Color(.systemGray5)).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
            .padding(.vertical, 4)
    }

    private func adminButton(_ title: String, color: Color, systemImage: String,
                              action: @escaping () async -> Void) -> some View {
        Button { Task { await action() } } label: {
            HStack {
                Image(systemName: systemImage)
                Text(title).font(.system(size: 14, weight: .medium))
            }.frame(maxWidth: .infinity).padding(8)
        }
        .background(color.opacity(0.8)).foregroundColor(.white).cornerRadius(8)
    }

    // MARK: - Cargo

    private var cargoManagementView: some View {
        VStack(spacing: 8) {
            adminField("Трек груза", text: $vm.cargoTrack, focus: .cargoTrack)
            adminField("Новый тип", text: $vm.newCargoType, focus: .newCargoType)
            adminField("Новая доставка", text: $vm.newDelivery, focus: .newDelivery)
            adminNumField("Новая цена", value: $vm.newPrice, focus: .newPrice)
            adminNumField("Новая масса", value: $vm.newMass, focus: .newMass)
            adminNumField("Новое значение", value: $vm.newValue, focus: .newValue)
            adminToggle("Упаковка", isOn: $vm.newPack)
            adminToggle("Страховка", isOn: $vm.newIns)
            HStack(spacing: 8) {
                adminButton("Создать", color: .blue, systemImage: "plus") { await vm.createCargo() }
                adminButton("Обновить", color: .blue, systemImage: "arrow.clockwise") { await vm.updateCargo() }
                adminButton("Удалить", color: .red, systemImage: "trash") { await vm.deleteCargo() }
            }.padding(.top, 4)
        }
        .padding(12).background(Color.white).cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3).padding(.horizontal)
    }

    // MARK: - Clients

    private var clientManagementView: some View {
        VStack(spacing: 8) {
            adminField("Телефон клиента", text: $vm.clientPhone, keyboard: .phonePad, focus: .clientPhone)
            adminField("Новый адрес", text: $vm.newClientAddress, focus: .newClientAddress)
            adminField("Новое ФИО", text: $vm.newClientFio, focus: .newClientFio)
            adminField("Новый пароль", text: $vm.newClientPassword, isSecure: true, focus: .newClientPassword)
            HStack(spacing: 8) {
                adminButton("Создать", color: .blue, systemImage: "person.crop.circle.badge.plus") { await vm.createClient() }
                adminButton("Обновить", color: .blue, systemImage: "arrow.clockwise") { await vm.updateClient() }
                adminButton("Удалить", color: .red, systemImage: "trash") { await vm.deleteClient() }
            }.padding(.top, 4)
        }
        .padding(12).background(Color.white).cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3).padding(.horizontal)
    }

    // MARK: - Points

    private var pointManagementView: some View {
        VStack(spacing: 8) {
            adminField("Название пункта", text: $vm.pointName, focus: .pointName)
            adminField("Новый телефон", text: $vm.newPointPhone, keyboard: .phonePad, focus: .newPointPhone)
            adminField("Новый адрес", text: $vm.newPointAddress, focus: .newPointAddress)
            HStack(spacing: 8) {
                adminButton("Создать", color: .blue, systemImage: "plus") { await vm.createPoint() }
                adminButton("Обновить", color: .blue, systemImage: "arrow.clockwise") { await vm.updatePoint() }
                adminButton("Удалить", color: .red, systemImage: "trash") { await vm.deletePoint() }
            }.padding(.top, 4)
        }
        .padding(12).background(Color.white).cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3).padding(.horizontal)
    }

    // MARK: - Employees

    private var employeeManagementView: some View {
        VStack(spacing: 8) {
            adminField("ФИО сотрудника", text: $vm.employeeFio, focus: .employeeFio)
            Picker("Новая позиция", selection: $vm.newEmployeePosition) {
                Text("Руководитель").tag("Руководитель")
                Text("Администратор").tag("Администратор")
                Text("Оператор").tag("Оператор")
                Text("Работник склада").tag("Работник склада")
                Text("Менеджер").tag("Менеджер")
            }.pickerStyle(SegmentedPickerStyle()).padding(.vertical, 2)
            adminField("Новый телефон", text: $vm.newEmployeePhone, keyboard: .phonePad, focus: .newEmployeePhone)
            adminField("Новый пароль", text: $vm.newEmployeePassword, isSecure: true, focus: .newEmployeePassword)
            HStack(spacing: 8) {
                adminButton("Создать", color: .blue, systemImage: "person.crop.circle.badge.plus") { await vm.createEmployee() }
                adminButton("Обновить", color: .blue, systemImage: "arrow.clockwise") { await vm.updateEmployee() }
                adminButton("Удалить", color: .red, systemImage: "trash") { await vm.deleteEmployee() }
            }.padding(.top, 4)
        }
        .padding(12).background(Color.white).cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 5, x: 0, y: 3).padding(.horizontal)
    }
}
