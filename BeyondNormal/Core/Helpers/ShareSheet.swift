import SwiftUI
import UIKit
import LinkPresentation

enum ShareContentType {
    case award(Award)
    case summary(String)
}

// Text provider ensures Messages gets NSString (prevents blank body)
final class BNSharePayload: NSObject, UIActivityItemSource {
    private let text: String
    init(text: String) {
        self.text = text
        super.init()
    }
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
        var shareText = ""
        var shareImage: UIImage? = nil

        if let ctx = self.context {
            switch ctx {
            case .award(let award):
                shareText = """
                🔥 Beyond Normal
                \(award.title)
                Earned by \(award.subtitle.replacingOccurrences(of: "EARNED BY ", with: ""))

                Strength redefined. Train smarter. Live stronger.
                https://apps.apple.com/app/beyond-normal-strength/idXXXXXXXXX
                """
                shareImage = AwardGenerator.shared.resolveUIImage(award.frontImagePath)

            case .summary(let s):
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                shareText = trimmed.isEmpty
                ? """
                  🔥 Beyond Normal
                  Workout summary

                  Strength redefined. Train smarter. Live stronger.
                  https://apps.apple.com/app/beyond-normal-strength/idXXXXXXXXX
                  """
                : """
                  🔥 Beyond Normal
                  Today's workout summary:

                  \(trimmed)

                  Strength redefined. Train smarter. Live stronger.
                  https://apps.apple.com/app/beyond-normal-strength/idXXXXXXXXX
                  """
            }
        }

        // Items: include medal image for awards, plus text payload (as NSString)
        var items: [Any] = []
        if let img = shareImage {
            items.append(img)
        }
        items.append(BNSharePayload(text: shareText))

        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.excludedActivityTypes = [.assignToContact, .addToReadingList, .print]
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
