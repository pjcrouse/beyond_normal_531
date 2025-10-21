import SwiftUI

enum TourTargetID: Hashable {
    case settingsGear
    case displayName
    case trainingMaxes
}

final class TourController: ObservableObject {
    @AppStorage("bn.has_seen_quick_tour") var hasSeenQuickTour: Bool = false
    @Published var isActive = false
    @Published var currentTarget: TourTargetID? = nil

    func startHighlightingGearIfFirstRun() {
        guard hasSeenQuickTour == false else { return }
        currentTarget = .settingsGear
        isActive = true
    }

    func complete() {
        isActive = false
        hasSeenQuickTour = false // change to true once you don't want it to run all the time
        currentTarget = nil
    }
    
    func go(to target: TourTargetID) {
        currentTarget = target
        isActive = true
    }

    var titleForCurrent: String {
        switch currentTarget {
        case .settingsGear:   return "Start here"
        case .displayName:    return "Set Display Name"
        case .trainingMaxes:  return "Set Training Maxes"
        case .none:           return ""
        }
    }

    var messageForCurrent: String {
        switch currentTarget {
        case .settingsGear:
            return "Tap the gear to personalize Beyond Normal."
        case .displayName:
            return "Your name prints on PR medals and share cards."
        case .trainingMaxes:
            return "Dial in your squat, bench, deadlift, press, and row."
        case .none:
            return ""
        }
    }
}
