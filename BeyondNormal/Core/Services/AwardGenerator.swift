// Core/Services/AwardGenerator.swift
import SwiftUI

final class AwardGenerator {
    static let shared = AwardGenerator()
    private init() {}

    private var awardsDir: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Awards", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    @MainActor
    func createAndStoreAward(for pr: PersonalRecord,
                             userDisplayName: String,
                             store: AwardStore) async {
        let pounds = Int(round(pr.value))
        let title = "\(pounds) LB \(pr.lift.rawValue.capitalized) PR"
        let backLine1 = "\(pounds) LB"
        let backLine2 = "\(pr.lift.rawValue.uppercased()) PR"

        // These are the views now defined in Views/…
        let front = MedalFrontView()
        let back  = MedalBackView(
            user: userDisplayName,
            line1: backLine1,
            line2: backLine2,
            date: pr.date
        )

        let id = UUID()
        let frontURL = awardsDir.appendingPathComponent("\(id.uuidString)-front.png")
        let backURL  = awardsDir.appendingPathComponent("\(id.uuidString)-back.png")

        render(front, to: frontURL, square: 1024)
        render(back,  to: backURL,  square: 1024)

        let award = Award(
            id: id,
            lift: pr.lift,
            title: title,
            subtitle: "EARNED BY \(userDisplayName.uppercased())",
            date: pr.date,
            frontImagePath: frontURL.lastPathComponent,
            backImagePath:  backURL.lastPathComponent
        )
        store.add(award)
    }

    @MainActor
    private func render<V: View>(_ view: V, to url: URL, square: CGFloat) {
        let renderer = ImageRenderer(content: view.frame(width: square, height: square))
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage, let data = uiImage.pngData() {
            try? data.write(to: url)
        }
    }

    func resolveImage(_ relative: String) -> Image? {
        let url = awardsDir.appendingPathComponent(relative)
        if let uiimg = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: uiimg)
        }
        return nil
    }
}
