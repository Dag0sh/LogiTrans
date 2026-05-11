import SwiftUI

struct ManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Менеджер")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                    Divider().background(Color(.systemGray3))
                }
                .background(Color.white)
                .shadow(color: Color(.black).opacity(0.04), radius: 2, x: 0, y: 1)

                ZStack {
                    if selectedTab == 0 {
                        WarehouseLoadView()
                    } else {
                        ClientsListView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    tabButton(index: 0, title: "Отчёты", icon: "chart.bar.fill")
                    tabButton(index: 1, title: "Клиенты", icon: "person.2.fill")
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
                .background(Color(.systemGray5).opacity(0.7).ignoresSafeArea(edges: .bottom))
            }
        }
    }

    private func tabButton(index: Int, title: String, icon: String) -> some View {
        Button { withAnimation { selectedTab = index } } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(selectedTab == index ? .blue : Color(.systemGray))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedTab == index ? .blue : Color(.systemGray))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if selectedTab == index {
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
