import SwiftUI

struct WarehouseLoadView: View {
    @StateObject private var vm = WarehouseLoadViewModel()

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Header
                    VStack(spacing: 4) {
                        Text("Отчёты")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        Divider().background(Color(.systemGray3))
                    }

                    // MARK: - Load button / status
                    if vm.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Загрузка…").foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        Button {
                            Task { await vm.loadData() }
                        } label: {
                            Label("Обновить данные", systemImage: "arrow.clockwise")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                        }
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if let err = vm.error {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Income reports
                    sectionCard(title: "Доходы по типам грузов", icon: "chart.bar.fill") {
                        if vm.reports.isEmpty {
                            emptyRow("Нет данных о доходах")
                        } else {
                            ForEach(vm.reports) { report in
                                reportRow(report)
                                if report.id != vm.reports.last?.id {
                                    Divider().padding(.horizontal, 4)
                                }
                            }
                        }
                    }

                    // MARK: - Warehouse load
                    sectionCard(title: "Загруженность складов", icon: "shippingbox.fill") {
                        if vm.loads.isEmpty {
                            emptyRow("Нет данных о складах")
                        } else {
                            ForEach(vm.loads) { load in
                                warehouseRow(load)
                                if load.id != vm.loads.last?.id {
                                    Divider().padding(.horizontal, 4)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .refreshable { await vm.loadData() }
        }
        .onAppear { Task { await vm.loadData() } }
    }

    // MARK: - Subviews

    private func sectionCard<Content: View>(title: String, icon: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color(.systemGray3).opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private func reportRow(_ report: Report) -> some View {
        let periodStr: String = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ru_RU")
            f.dateFormat = "LLLL yyyy"
            return f.string(from: report.period).capitalized
        }()

        return HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(report.cargoType.capitalized)
                    .font(.system(size: 14, weight: .medium))
                Text(periodStr)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Отгрузок: \(report.count)  ·  Средняя: \(formatPrice(report.avgPrice)) ₽")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(formatPrice(report.income)) ₽")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.green)
        }
        .padding(.vertical, 6)
    }

    private func warehouseRow(_ load: WarehouseLoad) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2")
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(load.pointName)
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Text("\(load.occupiedSlots)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(load.occupiedSlots == 0 ? .secondary : .primary)
            Text("слотов занято")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }

    private func formatPrice(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}
