import Foundation

func int(_ x: Double) -> String {
    x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
}

func intOrDash(_ x: Double) -> String {
    guard x.isFinite else { return "—" }
    return x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
}
