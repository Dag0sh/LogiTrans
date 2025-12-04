import SwiftUI

extension Shipment: Equatable {
    static func == (lhs: Shipment, rhs: Shipment) -> Bool {
        return lhs.cargoTrack == rhs.cargoTrack &&
            lhs.pointName == rhs.pointName &&
            lhs.slot == rhs.slot &&
            lhs.status == rhs.status &&
            lhs.employeeFio == rhs.employeeFio &&
            lhs.date == rhs.date
    }
}

struct ClientTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var track = ""
    @State private var statuses: [Shipment] = []
    @State private var error: String?
    @State private var isLoading = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("Отслеживание груза")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.top, 32)

                    HStack {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.gray)
                        TextField("Введите трек-номер", text: $track)
                            .font(.system(size: 18))
                            .focused($isTextFieldFocused)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 24)

                    let isDisabled = isLoading || track.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    let buttonBackgroundColor: Color = isDisabled ? Color.gray.opacity(0.25) : Color.blue

                    Button(action: {
                        isLoading = true
                        error = nil
                        statuses = []
                        Task {
                            do {
                                let response = try await NetworkManager.shared.getCargoStatus(track: track)
                                statuses = response
                                if statuses.isEmpty {
                                    error = "Груз не найден"
                                }
                            } catch let err {
                                error = err.localizedDescription
                            }
                            isLoading = false
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 5)
                            }
                            Text("Проверить")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isDisabled)
                    .padding()
                    .background(buttonBackgroundColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                }
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 8)
                .padding(.top, 32)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)

                if let err = error {
                    Text(err)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal, 32)
                }

                if !statuses.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Статусы перемещения:")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.leading, 12)
                            .padding(.top, 16)
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(statuses, id: \.cargoTrack) { status in
                                    ClientTrackingStatusRow(status: status, formatter: formatDate)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(13)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 26)
                        .transition(.opacity)
                        .animation(.easeInOut, value: statuses)
                    }
                } 

                Spacer()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
}

struct ClientTrackingStatusRow: View {
    let status: Shipment
    let formatter: (Date) -> String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            let isDelivered = status.status == "Доставлен"
            Circle()
                .fill(isDelivered ? Color.green : Color.blue)
                .frame(width: 11, height: 11)
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.pointName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black)
                Text(status.status)
                    .foregroundColor(isDelivered ? .green : .blue)
                    .font(.system(size: 15))
                Text(formatter(status.date))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(11)
        .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)
    }
}
