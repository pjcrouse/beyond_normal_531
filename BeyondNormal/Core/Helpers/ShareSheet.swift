// Core/Helpers/ShareSheet.swift
import SwiftUI
import UIKit
import LinkPresentation
import Foundation   // needed for .whitespacesAndNewlines and number formatting

// ---- Messages-safe text payload (uses NSString) ----
final class BNSharePayload: NSObject, UIActivityItemSource {
    private let text: String
    init(text: String) { self.text = text }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        text as NSString
    }
    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        text as NSString
    }
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let md = LPLinkMetadata()
        md.title = "Beyond Normal"
        return md
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var context: ShareContentType?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var finalText = ""
        var image: UIImage? = nil
        var items: [Any] = []  // set in switch; fallback to text payload if still empty

        // Brand wrapper used by ALL text-based cases
        func branded(title: String, body: String) -> String {
            """
            🔥 Beyond Normal — \(title)

            \(body)

            Train smarter. Live stronger.
            https://apps.apple.com/app/beyond-normal-strength/idXXXXXXXXX
            """
        }

        if let ctx = self.context {
            switch ctx {
            case .fileURL(let url):            // ✅ NEW: direct file share
                items = [url]

            case .summary(let summaryBody):
                finalText = branded(
                    title: "Workout Summary",
                    body: summaryBody.trimmingCharacters(in: .whitespacesAndNewlines)
                )

            case .weeklySummary(let result):
                let total = result.totalVolume.formatted(.number)
                let liftsBlock = result.lifts.map {
                    "\($0.lift): Vol \($0.totalVolume.formatted(.number)) lb" +
                    ($0.est1RM > 0 ? ", Est 1RM \($0.est1RM)" : "")
                }.joined(separator: "\n")
                let body =
                """
                Cycle \(result.cycle) • Week \(result.programWeek)
                Total Volume: \(total) lb

                \(liftsBlock)
                """
                finalText = branded(title: "Weekly Summary", body: body)

            case .award(let award):
                image = AwardGenerator.shared.resolveUIImage(award.frontImagePath)
                let body =
                """
                \(award.title)
                \(award.date.formatted(date: .abbreviated, time: .omitted))
                """
                finalText = branded(title: "PR Award", body: body)
            }
        }

        // If not a file share, build the standard text payload (NSString for iMessage reliability).
        if items.isEmpty {
            items = [BNSharePayload(text: finalText)]
            if let img = image { items.insert(img, at: 0) }
        }

        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.excludedActivityTypes = [.assignToContact, .addToReadingList, .print]
        return vc
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
