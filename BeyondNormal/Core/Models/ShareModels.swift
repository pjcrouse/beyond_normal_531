import Foundation

// MARK: - Share Content Type
enum ShareContentType {
    case award(Award)
    case summary(String)
    case weeklySummary(ProgramWeekSummaryResult)
}

// MARK: - Share Request
struct ShareRequest: Identifiable {
    let id = UUID()
    let context: ShareContentType
}
