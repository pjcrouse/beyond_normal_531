// Core/Logic/CycleProgress.swift
import Foundation

// Keep these internal (no `public`) so they match your app types' access level.
struct CycleKey: Hashable {
    let week: Int
    let lift: LiftType
}

enum CycleCompletionPolicy {
    case threeWeeksNoDeload
    case includeDeload
}

enum CycleProgress {

    static func expectedKeys(
        mains: [LiftType],
        policy: CycleCompletionPolicy
    ) -> Set<CycleKey> {
        let weeks = (policy == .includeDeload) ? [1,2,3,4] : [1,2,3]
        return Set(weeks.flatMap { w in mains.map { CycleKey(week: w, lift: $0) } })
    }

    /// Field-name agnostic: pass the key paths of your model.
    static func completedKeys<E>(
        history: [E],
        cycle: Int,
        mains: [LiftType],
        policy: CycleCompletionPolicy,
        cycleKP: KeyPath<E, Int>,
        weekKP: KeyPath<E, Int>,
        liftKP: KeyPath<E, LiftType>,
        isMainKP: KeyPath<E, Bool?>,
        isDeloadKP: KeyPath<E, Bool?>
    ) -> Set<CycleKey> {
        let includeDeload = (policy == .includeDeload)
        let filtered = history.filter { e in
            e[keyPath: cycleKP] == cycle &&
            mains.contains(e[keyPath: liftKP]) &&
            (e[keyPath: isMainKP] ?? true) &&
            (includeDeload || (e[keyPath: isDeloadKP] ?? false) == false)
        }
        return Set(filtered.map { e in
            CycleKey(week: e[keyPath: weekKP], lift: e[keyPath: liftKP])
        })
    }

    static func isWeekComplete<E>(
        history: [E],
        cycle: Int,
        week: Int,
        mains: [LiftType],
        cycleKP: KeyPath<E, Int>,
        weekKP: KeyPath<E, Int>,
        liftKP: KeyPath<E, LiftType>,
        isMainKP: KeyPath<E, Bool?>
    ) -> Bool {
        let liftsThisWeek = history
            .filter { e in
                e[keyPath: cycleKP] == cycle &&
                e[keyPath: weekKP] == week &&
                (e[keyPath: isMainKP] ?? true)
            }
            .map { $0[keyPath: liftKP] }
        return Set(liftsThisWeek).isSuperset(of: Set(mains))
    }

    static func isCycleComplete<E>(
        history: [E],
        cycle: Int,
        mains: [LiftType],
        policy: CycleCompletionPolicy,
        cycleKP: KeyPath<E, Int>,
        weekKP: KeyPath<E, Int>,
        liftKP: KeyPath<E, LiftType>,
        isMainKP: KeyPath<E, Bool?>,
        isDeloadKP: KeyPath<E, Bool?>
    ) -> Bool {
        let exp = expectedKeys(mains: mains, policy: policy)
        let got = completedKeys(
            history: history,
            cycle: cycle,
            mains: mains,
            policy: policy,
            cycleKP: cycleKP,
            weekKP: weekKP,
            liftKP: liftKP,
            isMainKP: isMainKP,
            isDeloadKP: isDeloadKP
        )
        return got.isSuperset(of: exp)
    }
}
