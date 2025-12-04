import SwiftUI

struct WarehouseLoadView: View {
    @State private var loads: [WarehouseLoad] = []
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Загруженность складов")
                .font(.title)
                .padding()
            Button("Загрузить данные") {
                loadData()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            if !loads.isEmpty {
                List(loads, id: \.pointName) { load in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(load.pointName)
                            .font(.headline)
                        Text("Занято слотов: \(load.occupiedSlots)")
                    }
                    .padding(.vertical, 4)
                }
            } else if let err = error {
                Text(err)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("Данные не загружены")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
        .refreshable {
            loadData()
        }
        .onAppear {
            loadData()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
    }

    private func loadData() {
        Task {
            do {
                loads = try await NetworkManager.shared.getWarehouseLoad()
                print("Loaded \(loads.count) points with occupied slots")
            } catch let err {
                error = err.localizedDescription
                print("Error loading warehouse: \(err.localizedDescription)")
            }
        }
    }
}
