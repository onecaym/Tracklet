import SwiftUI

struct RecentReportsView: View {
    @EnvironmentObject var store: AppStore
    
    private var recentReports: [Report] {
        Array(store.reports.prefix(20))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Недавние отчёты")
                .font(Theme.sectionFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(Array(recentReports.enumerated()), id: \.element.id) { index, r in
                        HStack(alignment: .center, spacing: 12) {
                            Text(formatDate(r.date))
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 88, alignment: .leading)
                            Text(store.brands.first(where: { $0.id == r.brandId })?.name ?? "—")
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 120, alignment: .leading)
                            ForEach(Array(store.reportFields.enumerated()), id: \.element.id) { i, _ in
                                Text(r.value(at: i).formatted(.number.grouping(.automatic)))
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(width: 64, alignment: .trailing)
                            }
                            Text(r.totalTests.formatted(.number.grouping(.automatic)))
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 72, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(index % 2 == 0 ? Theme.rowBackground : Theme.rowBackgroundAlt)
                        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .bottom)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Дата")
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 88, alignment: .leading)
            Text("Бренд")
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 120, alignment: .leading)
            ForEach(store.reportFields, id: \.id) { f in
                Text(f.label)
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .frame(width: 64, alignment: .trailing)
            }
            Text("Всего")
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.cardBackground)
        .overlay(Rectangle().frame(height: 2).foregroundStyle(Theme.border), alignment: .bottom)
    }
    
    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f.string(from: d)
    }
}
