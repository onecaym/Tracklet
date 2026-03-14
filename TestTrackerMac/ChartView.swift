import SwiftUI
import Charts

struct ChartView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedBrandId: Int64?
    @State private var months = 6
    @State private var exportAlert: String?
    @State private var kpiGoalText: String = "1"
    
    private var stats: [MonthlyStat] {
        store.db.getMonthlyStats(brandId: selectedBrandId, months: months)
    }
    
    private var targetValue: Int {
        Int(kpiGoalText) ?? 1
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Аналитика")
                    .font(Theme.sectionFont)
                    .foregroundStyle(Theme.textPrimary)
                settingsSection
                chartSection
                if !stats.isEmpty { summarySection }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            kpiGoalText = String(store.db.getKpiGoal())
        }
        .alert("Экспорт", isPresented: .init(get: { exportAlert != nil }, set: { if !$0 { exportAlert = nil } })) {
            Button("OK", role: .cancel) { exportAlert = nil }
        } message: {
            if let m = exportAlert { Text(m) }
        }
    }
    
    private var settingsSection: some View {
        GroupBox("Настройки графика") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 20) {
                    Text("Бренд:")
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.textPrimary)
                    brandMenu
                    Text("Период:")
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.textPrimary)
                    periodMenu
                }
                HStack(spacing: 12) {
                    Text("Цель KPI (ед./мес):")
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.textPrimary)
                    TextField("1", text: $kpiGoalText)
                        .textFieldStyle(.plain)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(width: 100)
                        .background(Theme.inputBackground)
                        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(Theme.cornerRadiusSmall)
                        .onChange(of: kpiGoalText) { newValue in
                            if let n = Int(newValue), n >= 0 {
                                store.db.setKpiGoal(n)
                            }
                        }
                }
            }
            .padding(12)
        }
        .groupBoxStyle(ThemeGroupBoxStyle())
    }
    
    private var brandMenu: some View {
        Menu {
            Button("Все бренды") { selectedBrandId = nil }
            Divider()
            ForEach(store.brands) { b in
                Button(b.name) { selectedBrandId = b.id }
            }
        } label: {
            HStack {
                Text(selectedBrandId == nil ? "Все бренды" : (store.brands.first(where: { $0.id == selectedBrandId })?.name ?? "—"))
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 200)
            .background(Theme.inputBackground)
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
    }
    
    private var periodMenu: some View {
        Menu {
            Button("3 месяца") { months = 3 }
            Button("6 месяцев") { months = 6 }
            Button("12 месяцев") { months = 12 }
            Button("24 месяца") { months = 24 }
        } label: {
            HStack {
                Text(periodLabel(months))
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 140)
            .background(Theme.inputBackground)
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
    }
    
    @ViewBuilder
    private var chartSection: some View {
        GroupBox {
            if stats.isEmpty {
                Text("Нет данных за выбранный период")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: 300)
            } else {
                analyticsChart
            }
        } label: {
            EmptyView()
        }
        .groupBoxStyle(ThemeGroupBoxStyle())
    }
    
    private var analyticsChart: some View {
        AnalyticsChartView(stats: stats, targetValue: targetValue, monthLabel: monthLabel)
    }
    
    private var summarySection: some View {
        let total = stats.reduce(0) { $0 + $1.total }
        let avg = total / stats.count
        let aboveTarget = stats.filter { $0.total >= targetValue }.count
        let brandName = store.brands.first(where: { $0.id == selectedBrandId })?.name ?? "Все бренды"
        return Text("\(brandName)  ·  Всего за период: \(total.formatted(.number.grouping(.automatic)))  ·  Среднее: \(avg)/мес  ·  Цель \(targetValue) выполнена: \(aboveTarget)/\(stats.count) мес.")
            .font(Theme.bodyFont)
            .foregroundStyle(Theme.textPrimary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBackground)
            .cornerRadius(8)
    }
    
    private func periodLabel(_ months: Int) -> String {
        switch months {
        case 3: return "3 месяца"
        case 6: return "6 месяцев"
        case 12: return "12 месяцев"
        case 24: return "24 месяца"
        default: return "\(months) мес."
        }
    }
    
    private func monthLabel(_ yyyyMM: String) -> String {
        let parts = yyyyMM.split(separator: "-")
        guard parts.count == 2, let m = Int(parts[1]) else { return yyyyMM }
        let names = ["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
        let year = String(parts[0].suffix(2))
        return "\(names[m - 1])/\(year)"
    }
}

// Отдельная структура, чтобы компилятор мог вывести типы графика.
private struct AnalyticsChartView: View {
    let stats: [MonthlyStat]
    let targetValue: Int
    let monthLabel: (String) -> String
    
    private var xAxisValues: [String] {
        stats.map { monthLabel($0.month) }
    }
    
    var body: some View {
        chartWithAxes
            .chartYAxisLabel("Сумма за месяц")
            .chartXAxisLabel("Месяц")
            .frame(height: 320)
    }
    
    private var chartWithAxes: some View {
        mainChart
            .chartXAxis {
                AxisMarks(position: .bottom, values: xAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.border)
                    AxisValueLabel(anchor: .top, collisionResolution: .disabled) {
                        Text(value.as(String.self) ?? "")
                            .foregroundStyle(Theme.textPrimary)
                            .font(Theme.smallFont)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.border)
                    AxisValueLabel(anchor: .trailing, collisionResolution: .disabled) {
                        Text("\(value.as(Double.self).map { Int($0) } ?? 0)")
                            .foregroundStyle(Theme.textPrimary)
                            .font(Theme.smallFont)
                    }
                }
            }
    }
    
    private var mainChart: some View {
        Chart {
            ForEach(stats, id: \.month) { s in
                LineMark(
                    x: .value("Месяц", monthLabel(s.month)),
                    y: .value("Всего", s.total)
                )
                .foregroundStyle(Color.white)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Месяц", monthLabel(s.month)),
                    y: .value("Всего", s.total)
                )
                .foregroundStyle(Color.white)
                .symbolSize(28)
                .annotation(position: .top, alignment: .center, spacing: 4) {
                    Text("\(s.total)")
                        .font(Theme.smallFont)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                }
                AreaMark(
                    x: .value("Месяц", monthLabel(s.month)),
                    y: .value("Всего", s.total)
                )
                .foregroundStyle(Color.white.opacity(0.15))
            }
            RuleMark(y: .value("Цель", targetValue))
                .foregroundStyle(Theme.danger.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
            goalPointMark
        }
    }
    
    /// Невидимая точка чуть левее центра пунктира — к ней привязана подпись цели.
    @ChartContentBuilder
    private var goalPointMark: some ChartContent {
        let idx = max(0, stats.count / 2 - 1)
        let mid = stats[idx]
        PointMark(
            x: .value("Месяц", monthLabel(mid.month)),
            y: .value("Цель", targetValue)
        )
        .symbolSize(0)
        .foregroundStyle(.clear)
        .annotation(position: .top, alignment: .center, spacing: 2) {
            goalBadge
        }
    }
    
    private var goalBadge: some View {
        Text("Цель KPI в месяц - \(targetValue)")
            .font(.custom("Avenir Next Demi Bold", size: 13))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.danger.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.danger.opacity(0.6), lineWidth: 1))
    }
}
