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

                // Program Configuration
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Program Configuration", systemImage: "calendar")
                        Text("Beyond Normal supports flexible programming to fit your schedule:")
                            .foregroundStyle(.primary)
                        FeatureRow("3 Days", "Squat, Bench, Deadlift", "3.circle.fill")
                        FeatureRow("4 Days", "Add Row OR Press as your 4th lift", "4.circle.fill")
                        FeatureRow("5 Days", "All five lifts (Squat, Bench, Deadlift, Row, Press)", "5.circle.fill")
                        Text("Configure in **Settings → Workouts per Week**. The app automatically adjusts which lifts appear, which TMs get progressed, and assistance options for each day.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // Quick Start
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Quick Start", systemImage: "sparkles")
                        NumberedStep(1, "Choose your program", detail: "Settings → Workouts per Week (3, 4, or 5 days).")
                        NumberedStep(2, "Set your Training Maxes", detail: "Settings → Training Maxes for each lift.")
                        NumberedStep(3, "Pick today's lift", detail: "Use the Week/Lift pickers on the main screen.")
                        NumberedStep(4, "Follow the 3 main sets", detail: "Check them off as you go; log AMRAP reps.")
                        NumberedStep(5, "Do BBB & assistance", detail: "5×10 at your chosen % TM, then 2–3 assistance sets.")
                        NumberedStep(6, "Finish workout", detail: "Tap **Finish Workout** to save to History.")
                    }
                }

                // Setting Your Initial TM
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Setting Your Initial TM", systemImage: "gauge")
                        Text("Most people don't know their real TM. Here's a safe starting method:")
                            .foregroundStyle(.primary)
                        Bullet("Use your best recent lift and take ~85–90% of it.")
                        Bullet("If you've never lifted: pick a weight for ~5 reps and estimate 1RM, then reduce by 10%.")
                        Bullet("Start conservatively — it's okay if the first cycle feels lighter.")
                        Text("Over time, let AMRAP estimates adjust it if you use auto mode. Configure in **Settings → Training Maxes**.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // Warmup Guidance
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Warmup Guidance", systemImage: "flame")
                        Text("Tap **Warmup Guidance** on the workout card for a smart ramp from bar → first set, with plate math per side.")
                            .foregroundStyle(.secondary)
                        FeatureRow("Bar first, then smart touches", "Two–five ramp steps based on your target weight.", "figure.strengthtraining.traditional")
                        FeatureRow("Accurate plate breakdown", "Uses your implement weight and rounding preference.", "scalemass")
                        FeatureRow("Specialty bar support", "Respects per-exercise bar weights from Implements.", "barbell")
                    }
                }

                // About 5/3/1 & Cycles
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("About 5/3/1 & Cycles", systemImage: "dial.high")
                        Text("5/3/1 is a simple but effective strength program. Each **cycle** has 3 'work' weeks and 1 deload week:")
                            .foregroundStyle(.primary)
                        Bullet("**Week 1 (5s):** 65%, 75%, 85% × 5+ reps")
                        Bullet("**Week 2 (3s):** 70%, 80%, 90% × 3+ reps")
                        Bullet("**Week 3 (5/3/1):** 75%, 85%, 95% × 5/3/1+ reps")
                        Bullet("**Week 4 (Deload):** 40%, 50%, 60% × 5 reps each")
                        Text("After completing all lifts in a week (if Auto-advance is on), you move to the next week. After Week 4, you advance to **Cycle 2, Week 1**, and your TMs increase based on your progression style.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Text("It's great for beginner → intermediate lifters because periodization is tricky, and 5/3/1 removes complexity. Many lifters use this for years with tweaks in assistance, volume, or auto-TM modes.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // AMRAP & 1RM Estimation
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("AMRAP & 1RM Estimation", systemImage: "bolt.fill")
                        Text("**AMRAP** = As Many Reps As Possible. The final set in Weeks 1–3 gets you as many reps as you can with good form.")
                            .foregroundStyle(.primary)
                        Text("The app estimates your 1RM using one of three formulas:")
                            .foregroundStyle(.secondary)
                        Bullet("**Epley** (default): Simple and standard, best for most users")
                        Bullet("**Brzycki**: More conservative at high rep ranges (10+ reps)")
                        Bullet("**Mayhew**: Research-based sigmoid curve, accounts for fatigue")
                        Text("Example (Epley): `estimated 1RM = weight × (1 + reps/30)`")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.blue)
                        Text("Change your formula in **Settings → 1RM Formula**. Most users should stick with Epley unless you regularly perform 10+ rep AMRAPs.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // Deload Week
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Deload Week", systemImage: "leaf.arrow.circlepath")
                        Text("Every fourth week is a **deload** — a planned recovery phase using lighter weights (40-60% TM) and lower volume.")
                            .foregroundStyle(.primary)
                        Text("It might feel like you're taking a step back, but deloads are where your body actually **adapts and grows stronger** from accumulated stress.")
                            .foregroundStyle(.secondary)
                        Bullet("Reduces fatigue and joint stress.")
                        Bullet("Allows nervous system and connective tissues to recover.")
                        Bullet("Prevents plateaus and burnout so you can progress for years.")
                        Text("During deload, you'll skip BBB and assistance work — focus on sleep, nutrition, stress management, and gentle movement like light cardio or mobility work. You'll be amazed how much stronger and more explosive you feel after a true recovery week.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // TM Progression
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("TM Progression Strategies", systemImage: "chart.line.uptrend.xyaxis")
                        Text("After each 4-week cycle, your Training Maxes increase. Choose your progression style:")
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Classic Progression (Default)**")
                                .font(.subheadline.weight(.semibold))
                            Bullet("Upper body (Bench, Row, Press): +5 lbs")
                            Bullet("Lower body (Squat, Deadlift): +10 lbs")
                            Text("Simple, steady, and the traditional 5/3/1 approach. Best for beginners.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Auto Progression (AMRAP-Based)**")
                                .font(.subheadline.weight(.semibold))
                            Bullet("Sets TM to 90% of your best AMRAP-estimated 1RM from the completed cycle")
                            Bullet("Capped at +10 lbs upper / +20 lbs lower per cycle (prevents overreaching)")
                            Bullet("Only progresses lifts you actually performed (respects 3/4/5 day config)")
                            Text("More responsive to your actual performance. Best for intermediate lifters who consistently hit strong AMRAPs.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        
                        Text("Choose in **Settings → TM Progression Style**. When you advance cycles, you'll see a summary showing old → new TMs.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // BBB & Assistance
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("BBB & Assistance Work", systemImage: "figure.run")
                        Text("After your 3 main sets, you'll do **Boring But Big (BBB)** volume work and assistance exercises:")
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("**BBB (5×10)**")
                                .font(.subheadline.weight(.semibold))
                            Bullet("5 sets of 10 reps at 50-70% of your TM (you choose in Settings)")
                            Bullet("Default is 50% — adjust in **Settings → Assistance (BBB)**")
                            Bullet("You can log custom weights per BBB set if needed")
                            Bullet("Skipped during deload week")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Assistance Exercises (2-3 sets)**")
                                .font(.subheadline.weight(.semibold))
                            Bullet("Choose one assistance exercise per main lift")
                            Bullet("Built-in library organized by category (legs, push, pull, core)")
                            Bullet("Configure in **Settings → Assistance Exercises**")
                            Bullet("Also skipped during deload week")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Smart Cascade Feature**")
                                .font(.subheadline.weight(.semibold))
                            Text("When you change the weight or reps on any BBB or assistance set, it automatically **cascades down** to all remaining sets in that exercise.")
                                .font(.footnote).foregroundStyle(.secondary)
                            Bullet("Change Set 1 weight → Sets 2-5 update automatically")
                            Bullet("Perfect for adjusting on the fly based on how you feel")
                            Bullet("Saves time — no need to update each set manually")
                        }
                    }
                }

                // Custom Assistance
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Custom Assistance Exercises", systemImage: "plus.circle")
                        Text("Create your own assistance exercises to personalize your training:")
                            .foregroundStyle(.primary)
                        NumberedStep(1, "Navigate to Settings", detail: "Settings → Assistance Exercises → choose a day.")
                        NumberedStep(2, "Tap the '+' button", detail: "Top-right corner of the exercise picker.")
                        NumberedStep(3, "Fill in details", detail: "Name, default weight/reps, category, focus areas.")
                        NumberedStep(4, "Select options", detail: "Choose if it uses implements (for plate math).")
                        Text("Your custom exercises appear in the \"Your Custom\" section. Search by name, edit metadata, or swipe to delete anytime.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // Trophy Room & Awards
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Trophy Room & Awards", systemImage: "trophy.fill")
                        Text("When you set a new **personal record (PR)**, the app automatically creates a commemorative medal to celebrate your achievement!")
                            .foregroundStyle(.primary)
                        
                        FeatureRow("Automatic generation", "Created when you beat your all-time best estimated 1RM", "sparkles")
                        FeatureRow("Personalized medals", "Features your name, lift type, weight, and date", "person.crop.circle.badge.star")
                        FeatureRow("3D flip view", "Tap any medal to see front and back with animation", "rotate.3d")
                        
                        Text("**Accessing Your Trophy Room:**")
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 4)
                        Bullet("Open **PRs & Awards** (top-right icon on main screen)")
                        Bullet("Scroll to the Awards section")
                        Bullet("Tap **Open Trophy Room** to see your full gallery")
                        
                        Text("Awards are generated for estimated 1RM PRs calculated from your AMRAP performance. Set your display name in **Settings → Profile** to personalize medals with your name (defaults to \"CHAMPION\" if not set).")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // History & Summaries
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("History & Week Summaries", systemImage: "clock.arrow.circlepath")
                        Text("Every workout is automatically saved with detailed metrics:")
                            .foregroundStyle(.primary)
                        Bullet("Date, lift, estimated 1RM (from AMRAP), and total volume")
                        Bullet("BBB % used and AMRAP reps")
                        Bullet("Notes you added that day")
                        
                        Text("**Program Week Summaries:**")
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 4)
                        Bullet("Tap any \"Cycle X, Week Y\" header in History")
                        Bullet("See all lifts completed that week with AMRAP results")
                        Bullet("View total volume and best estimated 1RMs")
                        Bullet("Track progress trends across cycles")
                        
                        Text("Find everything in **History** (top-left clock icon). Swipe left to delete entries or long-press for options like **Delete** or **Copy Summary**.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // Implements & Specialty Bars
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Implements & Specialty Bars", systemImage: "barbell")
                        Text("If you use specialty bars (Safety Squat Bar, EZ bar, trap bar, etc.), configure per-exercise implement weights for accurate calculations:")
                            .foregroundStyle(.primary)
                        NumberedStep(1, "Open Settings", detail: "Settings → Implements → Configure Implements.")
                        NumberedStep(2, "Set bar weights", detail: "Override default bar weight for each lift.")
                        NumberedStep(3, "Affects calculations", detail: "Used for plate math, warmup guidance, and displays.")
                        
                        Text("**Examples:**")
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 4)
                        Bullet("Safety Squat Bar: 75 lbs (not 45)")
                        Bullet("EZ Curl Bar: 25 lbs")
                        Bullet("Trap Bar: 60 lbs")
                        
                        Text("This ensures plate recommendations are accurate when using non-standard equipment. Warmup guidance automatically respects these weights.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // Rest Timer
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Rest Timer", systemImage: "timer")
                        Text("The Rest Timer card helps maintain consistent rest periods between sets:")
                            .foregroundStyle(.primary)
                        
                        FeatureRow("Two presets", "Regular sets (180s) and BBB/accessory (120s)", "2.circle.fill")
                        FeatureRow("Full controls", "Start, Pause, Resume, and Reset", "playpause.circle")
                        FeatureRow("Notifications", "Get notified when rest period completes", "bell.fill")
                        
                        Text("Configure timer durations in **Settings → Rest Timer**. Tip: 240s = 4:00, 180s = 3:00, 120s = 2:00.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // Pro Tips
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Pro Tips", systemImage: "lightbulb")
                        Tip("Auto-advance week", "Turn this on in Settings and the app will roll to the next week after all lifts are finished.")
                        Tip("Keyboard 'Done'", "A **Done** button appears above the keyboard to exit text fields quickly.")
                        Tip("Search assistance", "In exercise pickers, use the search bar to quickly find exercises by name.")
                        Tip("Cascade adjustments", "Change weight/reps on any BBB or assistance set and it cascades to all remaining sets — great for adjusting on the fly.")
                        Tip("Cycle tracking", "Current cycle and week appear at top of main screen — manual override in Settings if needed.")
                        Tip("TM adjustments", "You can manually adjust any TM between cycles if auto-progression feels too aggressive or conservative.")
                    }
                }

                // FAQ (collapsible)
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("FAQ", systemImage: "questionmark.circle")
                        FAQ("What is TM (Training Max)?",
                            "The working max used to compute set weights. Classic 5/3/1 uses ~90% of true 1RM. This is NOT your actual max — it's a training target that allows for progressive overload.")
                        FAQ("How do I switch from 4 days to 3 days?",
                            "Go to Settings → Workouts per Week and select 3 days. The app will only show Squat, Bench, and Deadlift in your rotation and won't progress Row or Press TMs.")
                        FAQ("Where do I change BBB %?",
                            "Settings → Assistance (BBB). Choose between 50–70% of TM. Start at 50% if you're new to the program.")
                        FAQ("Why is the estimated 1RM blank?",
                            "It appears after you enter AMRAP reps on the final set for Weeks 1–3. Week 4 (deload) has no AMRAP, so no estimate is calculated.")
                        FAQ("What's the difference between Classic and Auto progression?",
                            "Classic adds fixed amounts each cycle (+5/+10 lbs). Auto uses your best AMRAP performance to set the new TM to 90% of your estimated 1RM, capped at +10/+20 to prevent overreaching. Beginners should use Classic.")
                        FAQ("Why didn't my TM auto-increase the full amount?",
                            "Auto progression is capped at +10 lbs upper / +20 lbs lower per cycle to prevent overreaching. If your AMRAP suggested a bigger jump, it's intentionally limited for sustainable progress.")
                        FAQ("How do Awards work?",
                            "Awards are automatically generated when you set a new all-time PR (personal record) based on your estimated 1RM from AMRAP performance. They're stored in your Trophy Room, accessible from PRs & Awards.")
                        FAQ("Can I use different bars for different lifts?",
                            "Yes! Configure per-exercise bar weights in Settings → Implements. This affects plate math, warmup guidance, and weight displays. Great for specialty bars like SSB, trap bar, or EZ curl bar.")
                        FAQ("What happens during deload week?",
                            "Week 4 is your deload — a built-in recovery phase. You'll use lighter weights (40-60% TM), lower volume, and skip BBB/assistance work so your body can heal and adapt. Focus this week on sleep, nutrition, stress management, and gentle movement — light cardio, walks, mobility work. This isn't downtime; it's where progress locks in and you recharge for the next cycle.")
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
