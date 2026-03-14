import SwiftUI

// MARK: - Верхний таб-бар в стиле жидкого стекла

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection: NavigationItem? = .report
    
    private enum NavigationItem: Int, CaseIterable, Identifiable, Hashable {
        case report = 0
        case brands
        case analytics
        case recent
        
        var id: Int { rawValue }
        var title: String {
            switch self {
            case .report: return "Создать отчёт"
            case .brands: return "Бренды"
            case .analytics: return "Аналитика"
            case .recent: return "Недавние отчёты"
            }
        }
        var icon: String {
            switch self {
            case .report: return "chart.bar.doc.plain"
            case .brands: return "tag"
            case .analytics: return "chart.xyaxis.line"
            case .recent: return "list.bullet.rectangle"
            }
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            if store.hasCompletedOnboarding {
                mainContent
            } else {
                OnboardingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            tabBar
            contentArea
            statusBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if selection == nil { selection = .report }
        }
    }
    
    // Верхний таб-бар с эффектом жидкого стекла
    private var tabBar: some View {
        HStack(spacing: 0) {
            Text("Tracklet")
                .font(Theme.sectionFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.leading, Theme.spacingL)
            
            Spacer()
            
            HStack(spacing: Theme.spacingXS) {
                ForEach(NavigationItem.allCases, id: \.id) { item in
                    Button {
                        selection = item
                    } label: {
                        HStack(spacing: Theme.spacingS) {
                            Image(systemName: item.icon)
                                .font(.custom("Avenir Next Medium", size: 16))
                            Text(item.title)
                                .font(Theme.labelFont)
                        }
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .padding(.horizontal, Theme.spacingL)
                        .padding(.vertical, Theme.spacingS)
                        .contentShape(Rectangle())
                        .background {
                            if selection == item {
                                RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                                            .fill(Theme.sidebarGlass)
                                            .blendMode(.plusLighter)
                                    )
                                    .shadow(color: Theme.accent.opacity(0.25), radius: 6)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.spacingXS)
            
            Spacer()
        }
        .frame(height: 52)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Theme.glassWhite)
                        .blendMode(.plusLighter)
                )
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Theme.glassBorder)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )
        }
    }
    
    @ViewBuilder
    private var contentArea: some View {
        Group {
            switch selection ?? .report {
            case .report: ReportFormView()
            case .brands: BrandsView()
            case .analytics: ChartView()
            case .recent: RecentReportsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var statusBar: some View {
        HStack {
            Text("Брендов: \(store.brands.count)  ·  Отчётов: \(store.reports.count)  ·  Всего записей: \(store.totalTestsCount.formatted(.number.grouping(.automatic)))")
                .font(Theme.smallFont)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingS)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Theme.glassHighlight)
                        .blendMode(.plusLighter)
                )
        }
    }
}
