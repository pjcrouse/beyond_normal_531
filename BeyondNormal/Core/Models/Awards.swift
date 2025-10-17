// Models/Awards.swift
import Foundation
import SwiftUI

enum LiftType: String, Codable, CaseIterable {
    case deadlift, squat, bench, press, row
}

struct PersonalRecord: Codable, Hashable {
    var lift: LiftType
    var metric: PRMetric      // .oneRM or .estimatedOneRM
    var value: Double         // in lb (store as base unit)
    var date: Date
}

enum PRMetric: String, Codable { case oneRM, estimatedOneRM }

struct Award: Codable, Identifiable, Hashable {
    var id: UUID = .init()
    var lift: LiftType
    var title: String         // e.g., "500 LB DEADLIFT PR"
    var subtitle: String      // e.g., "EARNED BY PAT"
    var date: Date
    var frontImagePath: String    // documents/Awards/<uuid>-front.png
    var backImagePath: String     // documents/Awards/<uuid>-back.png
}

final class AwardStore: ObservableObject {
    @Published private(set) var awards: [Award] = []
    private let url: URL

    init(filename: String = "awards.json") {
        url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        load()
    }
    func load() {
        if let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([Award].self, from: data) {
            awards = items.sorted{ $0.date > $1.date }
        }
    }
    func save() {
        let data = try? JSONEncoder().encode(awards)
        try? data?.write(to: url, options: .atomic)
    }
    func add(_ award: Award) {
        awards.insert(award, at: 0)
        save()
    }
}
extension LiftType {
    var frontImageAssetName: String {
        switch self {
        case .squat:    return "squat_medal_front"
        case .deadlift: return "deadlift_medal_front"
        case .bench:    return "bench_medal_front"
        case .press:    return "press_medal_front"
        case .row:      return "row_medal_front"
        }
    }
    var prBackImageAssetName: String {
        "medal_back_base"
    }
}
