import Foundation
import SQLite3

final class Database {
    private var db: OpaquePointer?
    private let path: String
    
    init(path: String? = nil) {
        let dir = path ?? FileManager.default.currentDirectoryPath
        self.path = (dir as NSString).appendingPathComponent("test_tracker.db")
        open()
        createTables()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    private func open() {
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Cannot open database: \(path)")
        }
    }
    
    private func createTables() {
        execute("""
            CREATE TABLE IF NOT EXISTS brands (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """)
        execute("""
            CREATE TABLE IF NOT EXISTS reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                brand_id INTEGER NOT NULL,
                date DATE NOT NULL,
                test_1 INTEGER DEFAULT 0,
                test_2 INTEGER DEFAULT 0,
                test_3 INTEGER DEFAULT 0,
                test_4 INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE CASCADE,
                UNIQUE(brand_id, date)
            )
            """)
        execute("CREATE INDEX IF NOT EXISTS idx_reports_date ON reports(date)")
        execute("CREATE INDEX IF NOT EXISTS idx_reports_brand_date ON reports(brand_id, date)")
        execute("""
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
            """)
        execute("""
            CREATE TABLE IF NOT EXISTS release_manager_stats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date DATE UNIQUE NOT NULL,
                sent_v1 INTEGER DEFAULT 0, on_review_v1 INTEGER DEFAULT 0, got_reject_v1 INTEGER DEFAULT 0,
                resubmitted_reject_v1 INTEGER DEFAULT 0, passed_v1 INTEGER DEFAULT 0, banned_v1 INTEGER DEFAULT 0, closed_v1 INTEGER DEFAULT 0,
                sent_v2 INTEGER DEFAULT 0, on_review_v2 INTEGER DEFAULT 0, got_reject_v2 INTEGER DEFAULT 0,
                resubmitted_reject_v2 INTEGER DEFAULT 0, passed_v2 INTEGER DEFAULT 0, banned_v2 INTEGER DEFAULT 0, closed_v2 INTEGER DEFAULT 0
            )
            """)
        execute("CREATE INDEX IF NOT EXISTS idx_rm_date ON release_manager_stats(date)")
        execute("""
            CREATE TABLE IF NOT EXISTS report_fields (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sort_order INTEGER NOT NULL,
                label TEXT NOT NULL
            )
            """)
        execute("CREATE INDEX IF NOT EXISTS idx_report_fields_order ON report_fields(sort_order)")
        ensureReportColumns()
    }
    
    private func ensureReportColumns() {
        for i in 5...15 {
            let col = "test_\(i)"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, "PRAGMA table_info(reports)", -1, &stmt, nil) == SQLITE_OK else { return }
            var hasColumn = false
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cstr = sqlite3_column_text(stmt, 1), String(cString: cstr) == col {
                    hasColumn = true
                    break
                }
            }
            sqlite3_finalize(stmt)
            if !hasColumn {
                execute("ALTER TABLE reports ADD COLUMN \(col) INTEGER DEFAULT 0")
            }
        }
    }
    
    // MARK: - Settings (KPI goal etc.)
    
    private static let kpiGoalKey = "kpi_goal"
    private static let onboardingDoneKey = "onboarding_done"
    private static let userRoleKey = "user_role"
    
    func getKpiGoal() -> Int {
        let sql = "SELECT value FROM settings WHERE key = ?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 1 }
        sqlite3_bind_text(stmt, 1, (Self.kpiGoalKey as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 1 }
        guard let cstr = sqlite3_column_text(stmt, 0) else { return 1 }
        return Int(String(cString: cstr)) ?? 1
    }
    
    func setKpiGoal(_ value: Int) {
        let sql = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (Self.kpiGoalKey as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (String(value) as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }
    
    func getOnboardingDone() -> Bool {
        getSetting(Self.onboardingDoneKey) == "1"
    }
    
    func setOnboardingDone(_ value: Bool) {
        setSetting(Self.onboardingDoneKey, value ? "1" : "0")
    }
    
    func getUserRole() -> String? {
        getSetting(Self.userRoleKey)
    }
    
    func setUserRole(_ value: String) {
        setSetting(Self.userRoleKey, value)
    }
    
    // MARK: - Report fields (custom role)
    
    func getReportFields() -> [ReportField] {
        let sql = "SELECT id, sort_order, label FROM report_fields ORDER BY sort_order"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        var result: [ReportField] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            result.append(ReportField(
                id: sqlite3_column_int64(stmt, 0),
                sortOrder: Int(sqlite3_column_int(stmt, 1)),
                label: String(cString: sqlite3_column_text(stmt, 2))
            ))
        }
        return result
    }
    
    func setReportFields(labels: [String]) -> Bool {
        guard sqlite3_exec(db, "DELETE FROM report_fields", nil, nil, nil) == SQLITE_OK else { return false }
        for (idx, label) in labels.enumerated() {
            let sql = "INSERT INTO report_fields (sort_order, label) VALUES (?, ?)"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
            sqlite3_bind_int(stmt, 1, Int32(idx + 1))
            sqlite3_bind_text(stmt, 2, (label as NSString).utf8String, -1, nil)
            guard sqlite3_step(stmt) == SQLITE_DONE else { sqlite3_finalize(stmt); return false }
            sqlite3_finalize(stmt)
        }
        return true
    }
    
    private func getSetting(_ key: String) -> String? {
        let sql = "SELECT value FROM settings WHERE key = ?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW, let cstr = sqlite3_column_text(stmt, 0) else { return nil }
        return String(cString: cstr)
    }
    
    private func setSetting(_ key: String, _ value: String) {
        let sql = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (value as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }
    
    private func execute(_ sql: String) {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_step(stmt)
    }
    
    // MARK: - Brands
    
    func addBrand(name: String) -> Brand? {
        let sql = "INSERT INTO brands (name) VALUES (?)"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_DONE else { return nil }
        return getBrand(id: sqlite3_last_insert_rowid(db))
    }
    
    func getBrand(id: Int64) -> Brand? {
        let sql = "SELECT id, name, created_at FROM brands WHERE id = ?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_int64(stmt, 1, id)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        let name = String(cString: sqlite3_column_text(stmt, 1))
        let created = isoDate(sqlite3_column_text(stmt, 2)) ?? Date()
        return Brand(id: sqlite3_column_int64(stmt, 0), name: name, createdAt: created)
    }
    
    func getAllBrands() -> [Brand] {
        let sql = "SELECT id, name, created_at FROM brands ORDER BY name"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        var result: [Brand] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            result.append(Brand(
                id: sqlite3_column_int64(stmt, 0),
                name: String(cString: sqlite3_column_text(stmt, 1)),
                createdAt: isoDate(sqlite3_column_text(stmt, 2)) ?? Date()
            ))
        }
        return result
    }
    
    func deleteBrand(id: Int64) -> Bool {
        let sql = "DELETE FROM brands WHERE id = ?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        sqlite3_bind_int64(stmt, 1, id)
        return sqlite3_step(stmt) == SQLITE_DONE && sqlite3_changes(db) > 0
    }
    
    func getBrandReportsCount(brandId: Int64) -> Int {
        let sql = "SELECT COUNT(*) FROM reports WHERE brand_id = ?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        sqlite3_bind_int64(stmt, 1, brandId)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }
    
    /// Удаляет все отчёты, бренды и настройки. Возвращает true при успехе.
    func deleteAllData() -> Bool {
        guard sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil) == SQLITE_OK else { return false }
        defer { sqlite3_exec(db, "ROLLBACK", nil, nil, nil) }
        guard sqlite3_exec(db, "DELETE FROM reports", nil, nil, nil) == SQLITE_OK else { return false }
        guard sqlite3_exec(db, "DELETE FROM brands", nil, nil, nil) == SQLITE_OK else { return false }
        guard sqlite3_exec(db, "DELETE FROM report_fields", nil, nil, nil) == SQLITE_OK else { return false }
        guard sqlite3_exec(db, "DELETE FROM settings", nil, nil, nil) == SQLITE_OK else { return false }
        return sqlite3_exec(db, "COMMIT", nil, nil, nil) == SQLITE_OK
    }
    
    // MARK: - Reports
    
    func addCombinedReport(date: Date, entries: [CombinedReportEntry]) -> Bool {
        guard sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil) == SQLITE_OK else { return false }
        defer { sqlite3_exec(db, "ROLLBACK", nil, nil, nil) }
        
        let dateStr = isoString(date)
        let updateSql = "UPDATE reports SET test_1=?, test_2=?, test_3=?, test_4=?, test_5=?, test_6=?, test_7=?, test_8=?, test_9=?, test_10=?, test_11=?, test_12=?, test_13=?, test_14=?, test_15=? WHERE brand_id=? AND date=?"
        let insertSql = "INSERT INTO reports (brand_id, date, test_1, test_2, test_3, test_4, test_5, test_6, test_7, test_8, test_9, test_10, test_11, test_12, test_13, test_14, test_15) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
        for entry in entries {
            var check: OpaquePointer?
            guard sqlite3_prepare_v2(db, "SELECT id FROM reports WHERE brand_id = ? AND date = ?", -1, &check, nil) == SQLITE_OK else { return false }
            sqlite3_bind_int64(check, 1, entry.brandId)
            sqlite3_bind_text(check, 2, (dateStr as NSString).utf8String, -1, nil)
            let hasRow = sqlite3_step(check) == SQLITE_ROW
            sqlite3_finalize(check)
            
            let v = entry.values
            let v15 = (0..<15).map { v.indices.contains($0) ? v[$0] : 0 }
            var stmt: OpaquePointer?
            if hasRow {
                guard sqlite3_prepare_v2(db, updateSql, -1, &stmt, nil) == SQLITE_OK else { return false }
                for (i, val) in v15.enumerated() { sqlite3_bind_int(stmt, Int32(i + 1), Int32(val)) }
                sqlite3_bind_int64(stmt, 16, entry.brandId)
                sqlite3_bind_text(stmt, 17, (dateStr as NSString).utf8String, -1, nil)
            } else {
                guard sqlite3_prepare_v2(db, insertSql, -1, &stmt, nil) == SQLITE_OK else { return false }
                sqlite3_bind_int64(stmt, 1, entry.brandId)
                sqlite3_bind_text(stmt, 2, (dateStr as NSString).utf8String, -1, nil)
                for (i, val) in v15.enumerated() { sqlite3_bind_int(stmt, Int32(i + 3), Int32(val)) }
            }
            guard sqlite3_step(stmt) == SQLITE_DONE else { sqlite3_finalize(stmt); return false }
            sqlite3_finalize(stmt)
        }
        return sqlite3_exec(db, "COMMIT", nil, nil, nil) == SQLITE_OK
    }
    
    func getReports(brandId: Int64? = nil, startDate: Date? = nil, endDate: Date? = nil) -> [Report] {
        var sql = "SELECT id, brand_id, date, test_1, test_2, test_3, test_4, test_5, test_6, test_7, test_8, test_9, test_10, test_11, test_12, test_13, test_14, test_15, created_at FROM reports WHERE 1=1"
        var params: [String] = []
        if let id = brandId { sql += " AND brand_id = ?"; params.append(String(id)) }
        if let d = startDate { sql += " AND date >= ?"; params.append(isoString(d)) }
        if let d = endDate { sql += " AND date <= ?"; params.append(isoString(d)) }
        sql += " ORDER BY date DESC"
        
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        for (i, p) in params.enumerated() {
            sqlite3_bind_text(stmt, Int32(i + 1), p, -1, nil)
        }
        var result: [Report] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            var values: [Int] = []
            for c in 3..<18 { values.append(Int(sqlite3_column_int(stmt, Int32(c)))) }
            result.append(Report(
                id: sqlite3_column_int64(stmt, 0),
                brandId: sqlite3_column_int64(stmt, 1),
                date: isoDate(sqlite3_column_text(stmt, 2)) ?? Date(),
                values: values,
                createdAt: isoDate(sqlite3_column_text(stmt, 18)) ?? Date()
            ))
        }
        return result
    }
    
    // MARK: - Release Manager stats
    
    func saveReleaseManagerReport(date: Date, sentV1: Int, onReviewV1: Int, gotRejectV1: Int, resubmittedRejectV1: Int, passedV1: Int, bannedV1: Int, closedV1: Int, sentV2: Int, onReviewV2: Int, gotRejectV2: Int, resubmittedRejectV2: Int, passedV2: Int, bannedV2: Int, closedV2: Int) -> Bool {
        let dateStr = isoString(date)
        let sql = """
            INSERT INTO release_manager_stats (date, sent_v1, on_review_v1, got_reject_v1, resubmitted_reject_v1, passed_v1, banned_v1, closed_v1, sent_v2, on_review_v2, got_reject_v2, resubmitted_reject_v2, passed_v2, banned_v2, closed_v2)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(date) DO UPDATE SET sent_v1=excluded.sent_v1, on_review_v1=excluded.on_review_v1, got_reject_v1=excluded.got_reject_v1, resubmitted_reject_v1=excluded.resubmitted_reject_v1, passed_v1=excluded.passed_v1, banned_v1=excluded.banned_v1, closed_v1=excluded.closed_v1, sent_v2=excluded.sent_v2, on_review_v2=excluded.on_review_v2, got_reject_v2=excluded.got_reject_v2, resubmitted_reject_v2=excluded.resubmitted_reject_v2, passed_v2=excluded.passed_v2, banned_v2=excluded.banned_v2, closed_v2=excluded.closed_v2
            """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        sqlite3_bind_text(stmt, 1, (dateStr as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(sentV1)); sqlite3_bind_int(stmt, 3, Int32(onReviewV1)); sqlite3_bind_int(stmt, 4, Int32(gotRejectV1)); sqlite3_bind_int(stmt, 5, Int32(resubmittedRejectV1)); sqlite3_bind_int(stmt, 6, Int32(passedV1)); sqlite3_bind_int(stmt, 7, Int32(bannedV1)); sqlite3_bind_int(stmt, 8, Int32(closedV1))
        sqlite3_bind_int(stmt, 9, Int32(sentV2)); sqlite3_bind_int(stmt, 10, Int32(onReviewV2)); sqlite3_bind_int(stmt, 11, Int32(gotRejectV2)); sqlite3_bind_int(stmt, 12, Int32(resubmittedRejectV2)); sqlite3_bind_int(stmt, 13, Int32(passedV2)); sqlite3_bind_int(stmt, 14, Int32(bannedV2)); sqlite3_bind_int(stmt, 15, Int32(closedV2))
        return sqlite3_step(stmt) == SQLITE_DONE
    }
    
    func getReleaseManagerReport(date: Date) -> ReleaseManagerReport? {
        let dateStr = isoString(date)
        let sql = "SELECT id, date, sent_v1, on_review_v1, got_reject_v1, resubmitted_reject_v1, passed_v1, banned_v1, closed_v1, sent_v2, on_review_v2, got_reject_v2, resubmitted_reject_v2, passed_v2, banned_v2, closed_v2 FROM release_manager_stats WHERE date = ?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(stmt, 1, (dateStr as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        let id = sqlite3_column_int64(stmt, 0)
        let d = isoDate(sqlite3_column_text(stmt, 1)) ?? date
        return ReleaseManagerReport(
            id: id,
            date: d,
            sentV1: Int(sqlite3_column_int(stmt, 2)), onReviewV1: Int(sqlite3_column_int(stmt, 3)), gotRejectV1: Int(sqlite3_column_int(stmt, 4)), resubmittedRejectV1: Int(sqlite3_column_int(stmt, 5)), passedV1: Int(sqlite3_column_int(stmt, 6)), bannedV1: Int(sqlite3_column_int(stmt, 7)), closedV1: Int(sqlite3_column_int(stmt, 8)),
            sentV2: Int(sqlite3_column_int(stmt, 9)), onReviewV2: Int(sqlite3_column_int(stmt, 10)), gotRejectV2: Int(sqlite3_column_int(stmt, 11)), resubmittedRejectV2: Int(sqlite3_column_int(stmt, 12)), passedV2: Int(sqlite3_column_int(stmt, 13)), bannedV2: Int(sqlite3_column_int(stmt, 14)), closedV2: Int(sqlite3_column_int(stmt, 15))
        )
    }
    
    func getMonthlyStats(brandId: Int64? = nil, months: Int = 6) -> [MonthlyStat] {
        var start = Calendar.current.date(bySetting: .day, value: 1, of: Date()) ?? Date()
        for _ in 0..<months {
            start = Calendar.current.date(byAdding: .month, value: -1, to: start) ?? start
        }
        let startStr = isoString(start)
        
        let sumAll = (1...15).map { "COALESCE(test_\($0),0)" }.joined(separator: "+")
        var sql = """
            SELECT strftime('%Y-%m', date) as month,
                   COALESCE(SUM(test_1),0), COALESCE(SUM(test_2),0),
                   COALESCE(SUM(test_3),0), COALESCE(SUM(test_4),0),
                   COALESCE(SUM(\(sumAll)),0) as total
            FROM reports WHERE date >= ?
            """
        if brandId != nil { sql += " AND brand_id = ?" }
        sql += " GROUP BY strftime('%Y-%m', date) ORDER BY month"
        
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(stmt, 1, startStr, -1, nil)
        if let id = brandId { sqlite3_bind_int64(stmt, 2, id) }
        
        var dict: [String: MonthlyStat] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            let month = String(cString: sqlite3_column_text(stmt, 0))
            dict[month] = MonthlyStat(
                month: month,
                total: Int(sqlite3_column_int(stmt, 5)),
                v1: Int(sqlite3_column_int(stmt, 1)),
                v2: Int(sqlite3_column_int(stmt, 2)),
                v1Reject: Int(sqlite3_column_int(stmt, 3)),
                v2Reject: Int(sqlite3_column_int(stmt, 4))
            )
        }
        
        var current = start
        let end = Date()
        let cal = Calendar.current
        while current <= end {
            let key = monthKey(current)
            if dict[key] == nil {
                dict[key] = MonthlyStat(month: key, total: 0, v1: 0, v2: 0, v1Reject: 0, v2Reject: 0)
            }
            current = cal.date(byAdding: .month, value: 1, to: current) ?? current
        }
        return dict.keys.sorted().compactMap { dict[$0] }
    }
    
    private func isoString(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
    
    private func isoDate(_ ptr: UnsafePointer<UInt8>?) -> Date? {
        guard let ptr = ptr else { return nil }
        var str = String(cString: UnsafePointer<CChar>(OpaquePointer(ptr)))
        if let tIndex = str.firstIndex(of: "T") { str = String(str[..<tIndex]) }
        str = str.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: str) { return date }
        let utcFormatter = ISO8601DateFormatter()
        utcFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return utcFormatter.date(from: str + "T00:00:00Z")
    }
    
    private func monthKey(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }
}
