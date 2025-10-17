// Services/PRService.swift
import Foundation

struct LiftEntry {
    let lift: LiftType
    let weightLB: Double
    let reps: Int
    let date: Date
}

enum E1RMFormula { case epley, brzycki, lombardi }

func estimate1RM(weight: Double, reps: Int, using f: E1RMFormula) -> Double {
    guard reps > 1 else { return weight }
    switch f {
    case .epley:   return weight * (1.0 + Double(reps)/30.0)
    case .brzycki: return weight * 36.0 / (37.0 - Double(reps))
    case .lombardi:return weight * pow(Double(reps), 0.10)
    }
}

final class PRService {
    private let prsKey = "stored_prs_v1"
    private var prs: [PersonalRecord] = []

    init() { load() }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: prsKey),
           let x = try? JSONDecoder().decode([PersonalRecord].self, from: d) {
            prs = x
        }
    }
    private func save() {
        let d = try? JSONEncoder().encode(prs)
        UserDefaults.standard.set(d, forKey: prsKey)
    }

    func best(for lift: LiftType, metric: PRMetric) -> PersonalRecord? {
        prs.filter{ $0.lift == lift && $0.metric == metric }.max(by:{ $0.value < $1.value })
    }

    /// Returns PR record if a new PR was achieved (by >= 0.5 lb margin).
    func updateIfPR(entry: LiftEntry, metric: PRMetric, formula: E1RMFormula) -> PersonalRecord? {
        let value: Double = (metric == .oneRM && entry.reps == 1)
            ? entry.weightLB
            : estimate1RM(weight: entry.weightLB, reps: entry.reps, using: formula)

        let prev = best(for: entry.lift, metric: metric)?.value ?? 0
        if value >= prev + 0.5 {
            let pr = PersonalRecord(lift: entry.lift, metric: metric, value: value, date: entry.date)
            prs.append(pr); save()
            return pr
        }
        return nil
    }
}
// MARK: - Estimated 1RM direct update
extension PRService {
    /// Compare a computed estimated 1RM against stored PRs.
    /// Returns the new PR if it improved by >= 0.5 lb.
    func updateIfEstimatedPR(lift: LiftType, estValue: Double, date: Date) -> PersonalRecord? {
        let prev = best(for: lift, metric: .estimatedOneRM)?.value ?? 0
        if estValue >= prev + 0.5 {
            let pr = PersonalRecord(lift: lift, metric: .estimatedOneRM, value: estValue, date: date)
            prs.append(pr)
            // persist
            let d = try? JSONEncoder().encode(prs)
            UserDefaults.standard.set(d, forKey: "stored_prs_v1")
            return pr
        }
        return nil
    }
}
