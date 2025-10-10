import SwiftUI

struct UserGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Hero
                GuideHero(
                    title: "Beyond Normal",
                    subtitle: "5/3/1 training, simplified."
                )

                // Quick Start
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Quick Start", systemImage: "sparkles")
                        NumberedStep(1, "Set your Training Maxes", detail: "Open Settings → Training Maxes.")
                        NumberedStep(2, "Pick today’s lift", detail: "Use the Week/Lift pickers on the main screen.")
                        NumberedStep(3, "Follow the 3 main sets", detail: "Check them off as you go; log AMRAP reps.")
                        NumberedStep(4, "Do BBB & assistance", detail: "5×10 at your chosen % TM, then 2–3 assistance sets.")
                        NumberedStep(5, "Finish workout", detail: "Tap **Finish Workout** to save to History.")
                    }
                }

                // Warmup Guidance
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Warmup Guidance", systemImage: "flame")
                        Text("Tap **Warmup Guidance** on the workout card for a ramp from bar → first set, with plate math per side.")
                            .foregroundStyle(.secondary)
                        FeatureRow("Bar first, then smart touches", "Two–five ramp steps based on your target weight.", "figure.strengthtraining.traditional")
                        FeatureRow("Accurate plate breakdown", "Uses your implement weight and rounding preference.", "scalemass")
                    }
                }

                // What Gets Saved
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("What Gets Saved", systemImage: "tray.full")
                        Bullet("Date, lift, estimated 1RM (from AMRAP), and total volume.")
                        Bullet("BBB % used and AMRAP reps.")
                        Bullet("Notes you add that day.")
                        Text("Find everything in **History** (top-left clock icon).").foregroundStyle(.secondary)
                    }
                }

                // Tips
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Pro Tips", systemImage: "lightbulb")
                        Tip("Long-press or swipe", "In History, swipe left to delete an entry.")
                        Tip("Keyboard ‘Done’", "A **Done** button appears above the keyboard to exit text fields quickly.")
                        Tip("Auto-advance week", "Turn this on in Settings and the app will roll to the next week after all four lifts are finished.")
                        Tip("Implements editor", "Set per-exercise bar/EZ weights for precise plate math.")
                    }
                }

                // FAQ (collapsible)
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("FAQ", systemImage: "questionmark.circle")
                        FAQ("What is TM (Training Max)?",
                            "The working max used to compute set weights. Classic 5/3/1 uses ~90% of true 1RM.")
                        FAQ("Where do I change BBB %?",
                            "Settings → Assistance (BBB). Choose between 50–70% of TM.")
                        FAQ("Why is the estimated 1RM blank?",
                            "It appears after you enter AMRAP reps on the final set for Week 1–3.")
                        FAQ("Deload week?",
                            "Week 4 hides BBB/assistance and shows a short deload note on the main card.")
                    }
                }

                // Support + version
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Help & Support", systemImage: "person.crop.circle.badge.questionmark")
                        LinkRow(title: "Email Support", subtitle: "support@beyondnormal.app", systemImage: "envelope", url: URL(string: "mailto:support@beyondnormal.app")!)
                        if let url = URL(string: "https://beyondnormal.app/privacy") {
                            LinkRow(title: "Privacy Policy", subtitle: "How your data is handled", systemImage: "hand.raised", url: url)
                        }
                        Divider().padding(.vertical, 4)
                        HStack {
                            Label("Version", systemImage: "info.circle")
                            Spacer()
                            Text(AppInfo.versionString)
                                .font(.footnote).foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }

                Spacer(minLength: 4)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .navigationTitle("User Guide")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbar {
            // You already provide a Done button when presented as a sheet.
            // This adds one automatically when the view is pushed (e.g., from Settings).
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .opacity(isPresentedModally ? 1 : 0) // will still be hidden when genuinely pushed
                    .accessibilityHidden(!isPresentedModally)
            }
        }
    }

    // Detect if the view is presented modally (best effort).
    private var isPresentedModally: Bool {
        // If there's no presenting controller, we assume it's pushed.
        #if canImport(UIKit)
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.rootViewController?.presentedViewController != nil
        #else
        return false
        #endif
    }
}

// MARK: - Components

private struct GuideHero: View {
    let title: String
    let subtitle: String
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.15), Color.blue.opacity(0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40, weight: .semibold))
                    .imageScale(.large)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title2.weight(.bold))
                    Text(subtitle).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(18)
        }
        .overlay( // soft shadow
            RoundedRectangle(cornerRadius: 24).strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}

private struct GuideCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading) { content }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary, lineWidth: 1))
    }
}

private func SectionHeader(_ text: String, systemImage: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: systemImage).imageScale(.medium)
        Text(text).font(.headline)
        Spacer()
    }
}

private func NumberedStep(_ n: Int, _ title: String, detail: String? = nil) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
        ZStack {
            Circle().fill(Color.primary.opacity(0.08))
            Text("\(n)").font(.subheadline.weight(.semibold))
        }
        .frame(width: 26, height: 26)
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            if let detail = detail {
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        Spacer()
    }
}

private func FeatureRow(_ title: String, _ subtitle: String, _ symbol: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
        Image(systemName: symbol).imageScale(.large)
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(subtitle).font(.footnote).foregroundStyle(.secondary)
        }
        Spacer()
    }
}

private func Bullet(_ text: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
        Image(systemName: "circle.fill").font(.system(size: 6))
        Text(text).font(.subheadline)
        Spacer()
    }
}

private struct Tip: View {
    let title: String
    let detail: String
    init(_ title: String, _ detail: String) { self.title = title; self.detail = detail }
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "lightbulb").imageScale(.medium)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct FAQ: View {
    let q: String
    let a: String
    init(_ q: String, _ a: String) { self.q = q; self.a = a }
    @State private var open = false
    var body: some View {
        DisclosureGroup(isExpanded: $open) {
            Text(a).font(.footnote).foregroundStyle(.secondary).padding(.top, 4)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "q.circle").imageScale(.medium)
                Text(q).font(.subheadline.weight(.semibold))
            }
        }
    }
}

private struct LinkRow: View {
    let title: String, subtitle: String, systemImage: String, url: URL
    var body: some View {
        Link(destination: url) {
            HStack {
                Image(systemName: systemImage).imageScale(.medium)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").imageScale(.small).foregroundStyle(.secondary)
            }
        }.buttonStyle(.plain)
    }
}

// MARK: - AppInfo

private enum AppInfo {
    static var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "v\(v) (\(b))"
    }
}
