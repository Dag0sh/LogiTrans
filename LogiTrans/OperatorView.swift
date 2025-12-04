import SwiftUI

struct OperatorView: View {
    let currentEmployeeFio: String
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var track = ""
    @State private var type = "мелкий"
    @State private var delivery = "стандартная"
    @State private var sender = ""
    @State private var receiver = ""
    @State private var mass: Double? = 0
    @State private var value: Double? = 0
    @State private var pack = false
    @State private var ins = false
    @State private var price: Double = 0
    @State private var point = ""
    @State private var slot = ""
    @State private var status = "занято"
    @State private var error: String?
    @State private var showLogin: Bool = false
    @State private var points: [String] = []
    
    var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1)
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            if showLogin {
                LoginView()
            } else {
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 8) {
                            Text("Создание груза")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.gray)
                            Divider()
                                .background(Color(.systemGray3))
                                .padding(.horizontal, 36)
                        }
                        .padding(.top, 12)
                        
                        VStack(spacing: 18) {
                            Group {
                                TextField("Трек-номер", text: $track)
                                    .padding()
                                    .background(fieldBackground)
                                Picker("Тип груза", selection: $type) {
                                    Text("мелкий").tag("мелкий")
                                    Text("средний").tag("средний")
                                    Text("крупный").tag("крупный")
                                    Text("документный").tag("документный")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 2)

                                Picker("Доставка", selection: $delivery) {
                                    Text("стандартная").tag("стандартная")
                                    Text("срочная").tag("срочная")
                                    Text("экспресс").tag("экспресс")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 2)

                                TextField("Отправитель (телефон)", text: $sender)
                                    .keyboardType(.phonePad)
                                    .padding()
                                    .background(fieldBackground)
                                TextField("Получатель (телефон)", text: $receiver)
                                    .keyboardType(.phonePad)
                                    .padding()
                                    .background(fieldBackground)
                            }
                            
                            HStack(spacing: 12) {
                                TextField("Масса (кг)", value: $mass, formatter: NumberFormatter())
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(fieldBackground)
                                TextField("Значение (₽)", value: $value, formatter: NumberFormatter())
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(fieldBackground)
                            }

                            Toggle("Упаковка", isOn: $pack)
                                .padding()
                                .background(fieldBackground)
                            Toggle("Страховка", isOn: $ins)
                                .padding()
                                .background(fieldBackground)
                            
                            Button(action: {
                                Task {
                                    do {
                                        price = try await NetworkManager.shared.calculatePrice(mass: mass, type: type, delivery: delivery, pack: pack, ins: ins)
                                    } catch let err {
                                        error = getFriendlyError(err)
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rublesign.circle.fill")
                                    Text("Рассчитать цену")
                                        .font(.system(size: 17, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.blue)
                            .cornerRadius(10)

                            Text("Цена: \(price, specifier: "%.2f") ₽")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.gray)
                                .padding(.vertical, 4)

                            Picker("Пункт выдачи", selection: $point) {
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
                            
                            TextField("Слот", text: $slot)
                                .padding()
                                .background(fieldBackground)
                        }
                        .padding(.horizontal, 4)

                        Button(action: {
                            Task {
                                do {
                                    if price == 0 {
                                        price = try await NetworkManager.shared.calculatePrice(mass: mass, type: type, delivery: delivery, pack: pack, ins: ins)
                                    }
                                    try await NetworkManager.shared.insertCargo(track: track, type: type, delivery: delivery, sender: sender, receiver: receiver, price: price, mass: mass, value: value, pack: pack, ins: ins)
                                    try await NetworkManager.shared.insertShipment(cargoTrack: track, pointName: point, slot: slot, status: status, employeeFio: currentEmployeeFio, date: Date())
                                    error = "Создано!"
                                } catch let err{
                                    error = getFriendlyError(err)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(.white)
                                Text("Создать груз и отгрузку")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.blue.opacity(0.08), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 8)
                        .disabled(point.isEmpty || points.isEmpty)
                        
                        if let err = error {
                            Text(err)
                                .foregroundColor(err == "Создано!" ? .green : .red)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 480)
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
                            error = getFriendlyError(err)
                        }
                    }
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
    }

    func getFriendlyError(_ error: Error) -> String {
        let errStr = error.localizedDescription
        if errStr.contains("Неверный тип") {
            return "Неверный тип груза или доставки"
        } else if errStr.contains("Масса") {
            return "Масса должна быть положительной"
        } else if errStr.contains("Телефон") {
            return "Неверный формат телефона"
        } else {
            return "Неизвестная ошибка, проверьте данные"
        }
    }
}
