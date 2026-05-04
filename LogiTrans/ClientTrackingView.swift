import SwiftUI

struct ClientTrackingView: View {
    @StateObject private var vm = ClientTrackingViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("Отслеживание груза")
                        .font(.system(size: 26, weight: .bold)).foregroundColor(.gray).padding(.top, 32)

                    HStack {
                        Image(systemName: "barcode.viewfinder").foregroundColor(.gray)
                        TextField("Введите трек-номер", text: $vm.track)
                            .font(.system(size: 18)).focused($isTextFieldFocused)
                            .disableAutocorrection(true).textInputAutocapitalization(.never)
                    }
                    .padding().background(Color.white).cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1).padding(.horizontal, 24)

                    Button {
                        Task { await vm.search() }
                    } label: {
                        HStack {
                            if vm.isLoading { ProgressView().padding(.trailing, 5) }
                            Text("Проверить").font(.system(size: 17, weight: .semibold))
                        }.frame(maxWidth: .infinity)
                    }
                    .disabled(!vm.canSearch || vm.isLoading)
                    .padding()
                    .background(!vm.canSearch || vm.isLoading ? Color.gray.opacity(0.25) : Color.blue)
                    .foregroundColor(.white).cornerRadius(14).padding(.horizontal, 24)
                }
                .background(Color.white).cornerRadius(22)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 8)
                .padding(.top, 32).padding(.horizontal, 10).padding(.bottom, 8)

                if let err = vm.error {
                    Text(err).foregroundColor(.red).multilineTextAlignment(.center)
                        .padding(.top, 8).padding(.horizontal, 32)
                }

                if !vm.statuses.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Статусы перемещения:").font(.headline).foregroundColor(.gray)
                            .padding(.leading, 12).padding(.top, 16)
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(vm.statuses) { status in
                                    ClientTrackingStatusRow(status: status)
                                }
                            }.padding(.vertical, 8)
                        }
                        .background(Color(.systemGray6)).cornerRadius(13)
                        .padding(.horizontal, 10).padding(.bottom, 26)
                        .animation(.easeInOut, value: vm.statuses)
                    }
                }

                Spacer()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { Button("Закрыть") { dismiss() } }
        }
    }
}

struct ClientTrackingStatusRow: View {
    let status: Shipment

    private var isDelivered: Bool { status.status == "Доставлен" }
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: status.date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(isDelivered ? Color.green : Color.blue)
                .frame(width: 11, height: 11).padding(.top, 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.pointName).font(.system(size: 17, weight: .medium)).foregroundColor(.black)
                Text(status.status).foregroundColor(isDelivered ? .green : .blue).font(.system(size: 15))
                Text(formattedDate).font(.system(size: 14)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.white).cornerRadius(11)
        .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)
    }
}
