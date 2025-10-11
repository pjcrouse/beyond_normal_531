import Foundation
import SwiftUI

final class WorkoutStateManager: ObservableObject {
    @Published private(set) var state: [String: String] = [:]
    @Published private(set) var completedLifts: [String: [String]] = [:]
    
    private let stateKey = "workout_state_v2"
    private let liftsKey = "completed_lifts_by_week"
    private let finishedKey = "finished_workouts"  // NEW
    private var saveWorkItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.beyondnormal.workout.state", qos: .userInitiated)
    
    init() {
        // Load state asynchronously to avoid blocking app launch
        queue.async { [weak self] in
            self?.loadState()
            self?.loadCompletedLifts()
        }
    }
    
    private func loadState() {
        guard let json = UserDefaults.standard.string(forKey: stateKey),
              let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.state = [:]
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.state = dict
        }
    }
    
    private func saveState() {
        // Debounce saves to avoid excessive writes
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.queue.async {
                guard let data = try? JSONEncoder().encode(self.state),
                      let json = String(data: data, encoding: .utf8) else { return }
                UserDefaults.standard.set(json, forKey: self.stateKey)
            }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func loadCompletedLifts() {
        guard let json = UserDefaults.standard.string(forKey: liftsKey),
              let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.completedLifts = [:]
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.completedLifts = dict
        }
    }
    
    private func saveCompletedLifts() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let data = try? JSONEncoder().encode(self.completedLifts),
                  let json = String(data: data, encoding: .utf8) else { return }
            UserDefaults.standard.set(json, forKey: self.liftsKey)
        }
    }
    
    func getSetComplete(lift: String, week: Int, set: Int) -> Bool {
        let key = "\(lift)_w\(week)_set\(set)"
        return state[key] == "true"
    }
    
    func setSetComplete(lift: String, week: Int, set: Int, value: Bool) {
        let key = "\(lift)_w\(week)_set\(set)"
        state[key] = value ? "true" : "false"
        saveState()
    }
    
    func getAssistComplete(lift: String, week: Int, set: Int) -> Bool {
        let key = "\(lift)_w\(week)_assist\(set)"
        return state[key] == "true"
    }
    
    func setAssistComplete(lift: String, week: Int, set: Int, value: Bool) {
        let key = "\(lift)_w\(week)_assist\(set)"
        state[key] = value ? "true" : "false"
        saveState()
    }
    
    func getAMRAP(lift: String, week: Int) -> Int {
        let key = "\(lift)_w\(week)_amrap"
        return Int(state[key] ?? "0") ?? 0
    }
    
    func setAMRAP(lift: String, week: Int, reps: Int) {
        let key = "\(lift)_w\(week)_amrap"
        state[key] = String(reps)
        saveState()
    }
    
    // BBB set-specific weight adjustments
    func getBBBWeight(lift: String, week: Int, set: Int) -> Double? {
        let key = "\(lift)_w\(week)_bbb\(set)_weight"
        guard let str = state[key], let val = Double(str) else { return nil }
        return val
    }
    
    func setBBBWeight(lift: String, week: Int, set: Int, weight: Double?) {
        let key = "\(lift)_w\(week)_bbb\(set)_weight"
        if let weight = weight {
            state[key] = String(weight)
        } else {
            state.removeValue(forKey: key)
        }
        saveState()
    }
    
    // BBB set-specific reps
    func getBBBReps(lift: String, week: Int, set: Int) -> Int? {
        let key = "\(lift)_w\(week)_bbb\(set)_reps"
        guard let str = state[key], let val = Int(str) else { return nil }
        return val
    }
    
    func setBBBReps(lift: String, week: Int, set: Int, reps: Int?) {
        let key = "\(lift)_w\(week)_bbb\(set)_reps"
        if let reps = reps {
            state[key] = String(reps)
        } else {
            state.removeValue(forKey: key)
        }
        saveState()
    }
    
    // Assistance set-specific weight adjustments
    func getAssistWeight(lift: String, week: Int, set: Int) -> Double? {
        let key = "\(lift)_w\(week)_assist\(set)_weight"
        guard let str = state[key], let val = Double(str) else { return nil }
        return val
    }
    
    func setAssistWeight(lift: String, week: Int, set: Int, weight: Double?) {
        let key = "\(lift)_w\(week)_assist\(set)_weight"
        if let weight = weight {
            state[key] = String(weight)
        } else {
            state.removeValue(forKey: key)
        }
        saveState()
    }
    
    // Assistance set-specific reps
    func getAssistReps(lift: String, week: Int, set: Int) -> Int? {
        let key = "\(lift)_w\(week)_assist\(set)_reps"
        guard let str = state[key], let val = Int(str) else { return nil }
        return val
    }
    
    func setAssistReps(lift: String, week: Int, set: Int, reps: Int?) {
        let key = "\(lift)_w\(week)_assist\(set)_reps"
        if let reps = reps {
            state[key] = String(reps)
        } else {
            state.removeValue(forKey: key)
        }
        saveState()
    }
    
    // Assistance weight toggle (bodyweight vs weighted)
    func getAssistUseWeight(lift: String, week: Int) -> Bool {
        let key = "\(lift)_w\(week)_assist_useweight"
        return state[key] == "true"
    }
    
    func setAssistUseWeight(lift: String, week: Int, useWeight: Bool) {
        let key = "\(lift)_w\(week)_assist_useweight"
        state[key] = useWeight ? "true" : "false"
        saveState()
    }
    
    // NEW: Mark workout as finished
    func markWorkoutFinished(lift: String, week: Int) {
        let key = "\(lift)_w\(week)_finished"
        state[key] = "true"
        saveState()
    }
    
    // NEW: Check if workout is finished
    func isWorkoutFinished(lift: String, week: Int) -> Bool {
        let key = "\(lift)_w\(week)_finished"
        return state[key] == "true"
    }
    
    func markLiftComplete(_ lift: String, week: Int) {
        var lifts = completedLifts["w\(week)"] ?? []
        if !lifts.contains(lift) {
            lifts.append(lift)
            completedLifts["w\(week)"] = lifts
            saveCompletedLifts()
        }
    }
    
    func allLiftsComplete(for week: Int, totalLifts: Int) -> Bool {
        let lifts = completedLifts["w\(week)"] ?? []
        return lifts.count >= totalLifts
    }
    
    func resetCompletedLifts(for week: Int) {
        completedLifts["w\(week)"] = []
        saveCompletedLifts()
    }
    
    func resetLift(lift: String, week: Int) {
        for setNum in 1...8 {
            let key = "\(lift)_w\(week)_set\(setNum)"
            state.removeValue(forKey: key)
        }
        for setNum in 1...3 {
            state.removeValue(forKey: "\(lift)_w\(week)_assist\(setNum)")
            state.removeValue(forKey: "\(lift)_w\(week)_assist\(setNum)_weight")
            state.removeValue(forKey: "\(lift)_w\(week)_assist\(setNum)_reps")
        }
        state.removeValue(forKey: "\(lift)_w\(week)_assist_useweight")
        let amrapKey = "\(lift)_w\(week)_amrap"
        state.removeValue(forKey: amrapKey)
        
        // Clear BBB adjustments
        for setNum in 1...5 {
            state.removeValue(forKey: "\(lift)_w\(week)_bbb\(setNum)_weight")
            state.removeValue(forKey: "\(lift)_w\(week)_bbb\(setNum)_reps")
        }
        
        // NEW: Clear finished flag
        state.removeValue(forKey: "\(lift)_w\(week)_finished")
        
        saveState()
        
        // IMPORTANT: Also remove from completed lifts tracking
        var lifts = completedLifts["w\(week)"] ?? []
        lifts.removeAll { $0 == lift }
        completedLifts["w\(week)"] = lifts
        saveCompletedLifts()
    }
}
