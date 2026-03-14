import Foundation

struct ReportField: Identifiable {
    let id: Int64
    let sortOrder: Int
    let label: String
}

struct Brand: Identifiable {
    let id: Int64
    let name: String
    let createdAt: Date
}

struct Report: Identifiable {
    let id: Int64
    let brandId: Int64
    let date: Date
    let values: [Int]  // до 15 полей (test_1...test_15)
    let createdAt: Date
    
    var totalTests: Int { values.reduce(0, +) }
    func value(at index: Int) -> Int { index < values.count ? values[index] : 0 }
}

struct CombinedReportEntry: Identifiable {
    let id: UUID
    let brandId: Int64
    let values: [Int]  // до 15 полей
    
    init(id: UUID = UUID(), brandId: Int64, values: [Int]) {
        self.id = id
        self.brandId = brandId
        self.values = values
    }
    
    func value(at index: Int) -> Int { index < values.count ? values[index] : 0 }
}

struct MonthlyStat {
    let month: String  // "YYYY-MM"
    let total: Int
    let v1: Int
    let v2: Int
    let v1Reject: Int
    let v2Reject: Int
}

/// Один отчёт Release Manager за день (агрегированная статистика по V1/V2).
struct ReleaseManagerReport: Identifiable {
    let id: Int64
    let date: Date
    let sentV1: Int
    let onReviewV1: Int
    let gotRejectV1: Int
    let resubmittedRejectV1: Int
    let passedV1: Int
    let bannedV1: Int
    let closedV1: Int
    let sentV2: Int
    let onReviewV2: Int
    let gotRejectV2: Int
    let resubmittedRejectV2: Int
    let passedV2: Int
    let bannedV2: Int
    let closedV2: Int
}
