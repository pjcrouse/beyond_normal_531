import Foundation

// MARK: - Rounding

public struct LoadRounder {
    /// Rounds to the nearest increment (defaults to 0.5 if bad input)
    public static func round(_ x: Double, to increment: Double) -> Double {
        let inc = (increment.isFinite && increment > 0) ? increment : 0.5
        return (x / inc).rounded() * inc
    }
}

// MARK: - Plate Calculator

/// Stateless utility to compute per-side plates for a target barbell weight.
public final class PlateCalculator {
    private let barWeight: Double
    private let roundTo: Double
    private let inventory: [Double]
    private var cache: [String: [Double]] = [:]

    /// - Parameters:
    ///   - barWeight: implement/bar weight (lb)
    ///   - roundTo: rounding increment (lb)
    ///   - inventory: plate denominations available **per side** (lb), e.g., [45, 35, 25, 10, 5, 2.5]
    public init(barWeight: Double, roundTo: Double, inventory: [Double]) {
        self.barWeight = barWeight
        self.roundTo = roundTo
        self.inventory = inventory.filter { $0.isFinite && $0 > 0 }.sorted(by: >)
    }

    /// Public helper for other modules
    public func round(_ x: Double) -> Double {
        LoadRounder.round(x, to: roundTo)
    }

    /// Returns per-side plate list for a *total* target weight (bar + plates).
    public func plates(target: Double, barWeight: Double? = nil) -> [Double] {
        let bar = barWeight ?? self.barWeight
        let key = "\(target)_\(bar)"

        if let cached = cache[key] { return cached }

        guard target.isFinite, bar.isFinite, bar > 0, target >= bar else { return [] }
        var remainingPerSide = (target - bar) / 2.0
        guard remainingPerSide.isFinite, remainingPerSide >= 0 else { return [] }

        var out: [Double] = []
        for p in inventory {
            var guardCounter = 0
            while remainingPerSide + 1e-9 >= p && guardCounter < 200 {
                out.append(p)
                remainingPerSide -= p
                guardCounter += 1
            }
        }
        cache[key] = out
        return out
    }
}

// MARK: - Pretty formatting

public enum LoadFormat {
    /// "Per side: 45, 10, 2.5"
    public static func plateList(_ plates: [Double]) -> String {
        plates.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int($0))" : String(format: "%.1f", $0) }
              .joined(separator: ", ")
    }

    /// 215 -> "215", 215.5 -> "215.5"
    public static func intOr1dp(_ x: Double) -> String {
        x.rounded() == x ? String(format: "%.0f", x) : String(format: "%.1f", x)
    }
}
