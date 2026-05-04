import SwiftUI

struct WarehouseLoadView: View {
    @StateObject private var vm = WarehouseLoadViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Загруженность складов").font(.title).padding()

            Button("Загрузить данные") {
                Task { await vm.loadData() }
            }
            .padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)

            if !vm.loads.isEmpty {
                List(vm.loads) { load in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(load.pointName).font(.headline)
                        Text("Занято слотов: \(load.occupiedSlots)")
                    }
                    .padding(.vertical, 4)
                }
            } else if let err = vm.error {
                Text(err).foregroundColor(.red).padding()
            } else {
                Text("Данные не загружены").foregroundColor(.gray).padding()
            }
        }
        .padding()
        .refreshable { await vm.loadData() }
        .onAppear { Task { await vm.loadData() } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { Button("Закрыть") { dismiss() } }
        }
    }
}
