import SwiftUI

struct OperatorView: View {
    let currentEmployeeFio: String
    @StateObject private var vm = OperatorViewModel()
    @Environment(\.dismiss) private var dismiss

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1)
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Text("Создание груза")
                            .font(.system(size: 26, weight: .bold)).foregroundColor(.gray)
                        Divider().background(Color(.systemGray3)).padding(.horizontal, 36)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 18) {
                        Group {
                            TextField("Трек-номер", text: $vm.track).padding().background(fieldBackground)

                            Picker("Тип груза", selection: $vm.type) {
                                Text("мелкий").tag("мелкий")
                                Text("средний").tag("средний")
                                Text("крупный").tag("крупный")
                                Text("документный").tag("документный")
                            }.pickerStyle(SegmentedPickerStyle()).padding(.vertical, 2)

                            Picker("Доставка", selection: $vm.delivery) {
                                Text("стандартная").tag("стандартная")
                                Text("срочная").tag("срочная")
                                Text("экспресс").tag("экспресс")
                            }.pickerStyle(SegmentedPickerStyle()).padding(.vertical, 2)

                            TextField("Отправитель (телефон)", text: $vm.sender)
                                .keyboardType(.phonePad).padding().background(fieldBackground)
                            TextField("Получатель (телефон)", text: $vm.receiver)
                                .keyboardType(.phonePad).padding().background(fieldBackground)
                        }

                        HStack(spacing: 12) {
                            TextField("Масса (кг)", value: $vm.mass, formatter: NumberFormatter())
                                .keyboardType(.decimalPad).padding().background(fieldBackground)
                            TextField("Значение (₽)", value: $vm.value, formatter: NumberFormatter())
                                .keyboardType(.decimalPad).padding().background(fieldBackground)
                        }

                        Toggle("Упаковка", isOn: $vm.pack).padding().background(fieldBackground)
                        Toggle("Страховка", isOn: $vm.ins).padding().background(fieldBackground)

                        Button {
                            Task { await vm.calculatePrice() }
                        } label: {
                            HStack {
                                Image(systemName: "rublesign.circle.fill")
                                Text("Рассчитать цену").font(.system(size: 17, weight: .medium))
                            }.frame(maxWidth: .infinity)
                        }
                        .padding().background(Color(.systemGray5)).foregroundColor(.blue).cornerRadius(10)

                        Text("Цена: \(vm.price, specifier: "%.2f") ₽")
                            .font(.title3).bold().foregroundColor(.gray).padding(.vertical, 4)

                        Picker("Пункт выдачи", selection: $vm.point) {
                            if vm.points.isEmpty {
                                Text("Нет доступных пунктов").tag("")
                            } else {
                                ForEach(vm.points, id: \.self) { Text($0).tag($0) }
                            }
                        }.pickerStyle(MenuPickerStyle()).padding().background(fieldBackground)

                        TextField("Слот", text: $vm.slot).padding().background(fieldBackground)
                    }
                    .padding(.horizontal, 4)

                    Button {
                        Task { await vm.createCargo(employeeFio: currentEmployeeFio) }
                    } label: {
                        HStack {
                            Image(systemName: "shippingbox.fill").foregroundColor(.white)
                            Text("Создать груз и отгрузку").font(.system(size: 17, weight: .semibold))
                        }.frame(maxWidth: .infinity)
                    }
                    .padding().background(Color.blue).foregroundColor(.white).cornerRadius(14)
                    .shadow(color: Color.blue.opacity(0.08), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 8).disabled(!vm.canCreate)

                    if let msg = vm.statusMessage {
                        Text(msg)
                            .foregroundColor(vm.isError ? .red : .green)
                            .font(.subheadline).multilineTextAlignment(.center).padding(.top, 8)
                    }
                }
                .padding(.horizontal, 18).padding(.bottom, 32).frame(maxWidth: 480)
            }
            .onAppear { Task { await vm.loadPoints() } }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { Button("Закрыть") { dismiss() } }
        }
    }
}
