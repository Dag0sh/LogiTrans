import SwiftUI

struct LeaderTab {
    let view: AnyView
    let title: String
    let icon: String
}

struct LeaderView: View {
    let currentEmployeeFio: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    private var tabs: [LeaderTab] {
        [
            LeaderTab(view: AnyView(OperatorView(currentEmployeeFio: currentEmployeeFio)), title: "Оператор", icon: "person.2.fill"),
            LeaderTab(view: AnyView(AdminView()), title: "Админ", icon: "gearshape.fill"),
            LeaderTab(view: AnyView(WarehouseView()), title: "Склад", icon: "shippingbox.fill"),
            LeaderTab(view: AnyView(WarehouseLoadView()), title: "Отчёты", icon: "chart.bar.fill"),
            LeaderTab(view: AnyView(ClientTrackingView()), title: "Трекинг", icon: "barcode.viewfinder")
        ]
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Руководитель")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                    Divider().background(Color(.systemGray3))
                }
                .background(Color.white)
                .shadow(color: Color(.black).opacity(0.04), radius: 2, x: 0, y: 1)

                ZStack {
                    tabs[selectedTab].view
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                }

                HStack {
                    ForEach(0..<tabs.count, id: \.self) { idx in
                        Button(action: {
                            withAnimation { selectedTab = idx }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tabs[idx].icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(selectedTab == idx ? Color.blue : Color(.systemGray))
                                Text(tabs[idx].title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(selectedTab == idx ? Color.blue : Color(.systemGray))
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if selectedTab == idx {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: Color.blue.opacity(0.08), radius: 3, x: 0, y: 2)
                                            .padding(.horizontal, 8)
                                    }
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
                .background(Color(.systemGray5).opacity(0.7).ignoresSafeArea(edges: .bottom))
            }
        }
    }
}
