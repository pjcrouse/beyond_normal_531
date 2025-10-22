import SwiftUI

enum TourTargetID: Hashable {
    case settingsGear
    case displayName
    case trainingMaxes
    case helpIcon
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
        hasSeenQuickTour = true
        currentTarget = nil
    }
    
    func go(to target: TourTargetID) {
        currentTarget = target
        isActive = true
    }

    var titleForCurrent: String {
        switch currentTarget {
        case .settingsGear:
            return "Start Here"
        case .displayName:
            return "Set Display Name"
        case .trainingMaxes:
            return "Your Training Maxes"
        case .helpIcon:
            return "Need Help?"
        case .none:
            return ""
        }
    }

    var messageForCurrent: String {
        switch currentTarget {
        case .settingsGear:
            return "Tap the gear to open Settings and personalize Beyond Normal."
        case .displayName:
            return "Your display name appears on PR medals and share cards."
        case .trainingMaxes:
            return """
Dial in your lift training maxes here in Settings.
Don’t know what they are or how to estimate them? That’s okay — the next step will show you where to find answers in the User Guide.
"""
        case .helpIcon:
            return "Tap the question mark next to the gear icon any time for help, tutorials, and FAQs."
        case .none:
            return ""
        }
    }
}
