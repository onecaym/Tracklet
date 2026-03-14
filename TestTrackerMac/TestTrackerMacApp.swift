import SwiftUI

@main
struct TestTrackerMacApp: App {
    @StateObject private var store = AppStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 920, minHeight: 650)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

/// Черновик формы отчёта — сохраняется при уходе с вкладки и восстанавливается при возврате.
struct ReportFormDraft {
    var date: Date
    var selectedBrandId: Int64?
    var currentValues: [Int]
    var combinedEntries: [CombinedReportEntry]
}

final class AppStore: ObservableObject {
    let db: Database
    @Published var brands: [Brand] = []
    @Published var reports: [Report] = []
    @Published var hasCompletedOnboarding: Bool = false
    @Published var roleName: String = ""
    @Published var reportFields: [ReportField] = []
    /// Черновик несохранённого отчёта (при переключении на другую вкладку не теряется).
    @Published var reportFormDraft: ReportFormDraft?
    
    init() {
        let dir: String
        if Bundle.main.bundlePath.hasSuffix(".app") || Bundle.main.bundlePath.contains(".app/") {
            dir = (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("TestTrackerMac", isDirectory: true).path)
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        } else {
            dir = FileManager.default.currentDirectoryPath
        }
        db = Database(path: dir)
        hasCompletedOnboarding = db.getOnboardingDone()
        roleName = db.getUserRole() ?? ""
        reportFields = db.getReportFields()
        if hasCompletedOnboarding && reportFields.isEmpty {
            _ = db.setReportFields(labels: ["V1", "V2", "V1 Reject", "V2 Reject"])
            reportFields = db.getReportFields()
        }
        refresh()
    }
    
    func refresh() {
        brands = db.getAllBrands()
        reports = db.getReports()
    }
    
    var totalTestsCount: Int {
        reports.reduce(0) { $0 + $1.totalTests }
    }
}
