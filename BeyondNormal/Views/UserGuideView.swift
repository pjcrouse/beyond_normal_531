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

                // 🔥 NEW: Finding Your Training Max (TM)
                // 🔥 UPDATED: Finding Your Training Max (TM)
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Finding Your Training Max (TM)", systemImage: "gauge.with.dots.needle.bottom.50percent")
                        Text("Your Training Max (TM) is the foundation of 5/3/1. It should be **~90% of your true 1-rep max** — a weight you know you can lift even on a bad day.")
                            .foregroundStyle(.primary)

                        Group {
                            Text("**For Brand New Lifters**")
                                .font(.subheadline.weight(.semibold))
                                .padding(.top, 6)

                            NumberedStep(1, "Learn the Movement (Week 1–2)",
                                         detail: """
                                         • Start with just the barbell (45 lb).
                                         • **Deadlift exception:** Use **full-size bumper plates** so the bar is at standard height. Bumpers exist as light as **10 lb**; go as light as needed while keeping standard height. If that’s still too heavy, pull from blocks, use bumper-plate risers, or start with **Romanian deadlifts**.
                                         • Do 3–5 sets of 5–8 reps.
                                         • Focus entirely on consistent, repeatable form — not load.
                                         • Great learning resources: **Juggernaut Training Systems – Pillars** series (Squat/Bench/Deadlift), **Barbell Medicine** technique articles/videos, **Stronger by Science** form guides, and **Alan Thrall**’s YouTube tutorials.
                                         """)

                            NumberedStep(2, "Warm Up Properly",
                                         detail: """
                                         • 5–10 minutes easy cardio + dynamic mobility.
                                         • **At least one** movement-specific warm-up set **with the bar** (usually just one is plenty).
                                         """)

                            NumberedStep(3, "Build to Your **5-Rep Max (5RM)**",
                                         detail: """
                                         • Start with the bar for 5 reps.
                                         • Use these **rules of thumb** for jumps:
                                           – If the last set felt **incredibly easy**, you can **double** the previous jump.
                                           – If you felt **any** struggle/slowdown, use steady jumps:
                                             • Squat / Deadlift: **+10–20 lb per set**
                                             • Bench / Press / Row: **+5–10 lb per set**
                                         • Rest 3–5 minutes between sets.
                                         • Stop when 5 reps are challenging but clean — like you might have 1–2 reps in reserve.
                                         • **Do not** grind or sacrifice form. That clean set is your working **5RM**.
                                         """)

                            NumberedStep(4, "Calculate Your TM",
                                         detail: """
                                         Enter your 5RM in the app. We estimate your 1RM and set TM automatically:

                                         `estimated 1RM ≈ 5RM × 1.15`
                                         `Training Max = estimated 1RM × 0.90`
                                         """)
                                .padding(.bottom, 2)
                        }

                        Group {
                            Text("**For Experienced Lifters**")
                                .font(.subheadline.weight(.semibold))
                                .padding(.top, 6)

                            Bullet("**Option 1: I know my 1RM** — Enter it, we set TM to **90%**.")
                            Bullet("**Option 2: I know my recent 5RM** — Enter it, we use the same formula: **TM = 5RM × 1.15 × 0.90**.")
                        }

                        Group {
                            Text("**Important Guidelines**")
                                .font(.subheadline.weight(.semibold))
                                .padding(.top, 6)

                            Bullet("✓ **When in doubt, go lighter.** It’s better to start too light and build than start too heavy and stall.")
                            Bullet("✓ **Week 1 should feel easy.** TM is conservative by design; intensity grows across the cycle.")
                            Bullet("✓ **Form over weight.** Starting light engrains technique. Strength comes quickly when movement quality is high.")
                            Bullet("✓ **Be honest.** Inflating numbers breaks the program.")
                            Bullet("✓ **Adjust if needed.** If the first cycle is far too easy or too hard, reset TMs before the next cycle.")
                        }

                        Group {
                            Text("**Red Flags Your TM Is Too High**")
                                .font(.subheadline.weight(.semibold))
                                .padding(.top, 6)

                            Bullet("You’re grinding in Week 1.")
                            Bullet("You’re failing reps before AMRAP.")
                            Bullet("Form breaks down on work sets.")
                            Bullet("You’re consistently missing target reps.")
                            Text("If these happen, lower TM by **~10%** and rebuild. That’s smart training, not failure.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }

                        // Philosophy note
                        Text("**No ‘practice weeks’ needed — just learn.** Be strict about form, start light, and let the program teach you. You’ll master the movements faster and progress longer.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
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
                        Text("It’s great for beginner → intermediate lifters because periodization is tricky, and 5/3/1 removes complexity. Many lifters use this for years with tweaks in assistance, volume, or auto-TM modes.")
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
                        Text("Every fourth week is a **deload** — a planned recovery phase using lighter weights (40–60% TM) and lower volume.")
                            .foregroundStyle(.primary)
                        Text("It might feel like you’re taking a step back, but deloads are where your body actually **adapts and grows stronger** from accumulated stress.")
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
                                .font(.subheadline)
                            Bullet("Upper body (Bench, Row, Press): +5 lb")
                            Bullet("Lower body (Squat, Deadlift): +10 lb")
                            Text("Simple, steady, and the traditional 5/3/1 approach. Best for beginners.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Auto Progression (AMRAP-Based)**")
                                .font(.subheadline)
                            Bullet("Sets TM to 90% of your best AMRAP-estimated 1RM from the completed cycle")
                            Bullet("Capped at +10 lb upper / +20 lb lower per cycle (prevents overreaching)")
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
                        Text("After your 3 main sets, you’ll do **Boring But Big (BBB)** volume work and assistance exercises:")
                            .foregroundStyle(.primary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("**BBB (5×10)**")
                                .font(.subheadline)
                            Bullet("5 sets of 10 reps at 50–70% of your TM (you choose in Settings)")
                            Bullet("Default is 50% — adjust in **Settings → Assistance (BBB)**")
                            Bullet("You can log custom weights per BBB set if needed")
                            Bullet("Skipped during deload week")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Assistance Exercises (2–3 sets)**")
                                .font(.subheadline)
                            Bullet("Choose one assistance exercise per main lift")
                            Bullet("Built-in library organized by category (legs, push, pull, core)")
                            Bullet("Configure in **Settings → Assistance Exercises**")
                            Bullet("Also skipped during deload week")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("**Smart Cascade Feature**")
                                .font(.subheadline)
                            Text("When you change the weight or reps on any BBB or assistance set, it automatically **cascades down** to all remaining sets in that exercise.")
                                .font(.footnote).foregroundStyle(.secondary)
                            Bullet("Change Set 1 weight → Sets 2–5 update automatically")
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
                        Text("When you set a new **personal record (PR)**, the app creates a commemorative medal.")
                            .foregroundStyle(.primary)

                        FeatureRow("Filter & Sort", "Filter by lift and sort by date or weight to find medals fast.", "line.3.horizontal.decrease.circle")
                        FeatureRow("Share your medals", "Open a medal → **Share Award** to send an image and details.", "square.and.arrow.up")
                        FeatureRow("3D medals", "Tap any medal and **flick to spin** with physics-based motion.", "rotate.3d")

                        Text("**Open the Trophy Room:** PRs & Awards → **Open Trophy Room**.")
                            .font(.subheadline)
                        Bullet("Tap a medal for a high-res 3D view")
                        Bullet("Use the menus above the grid to filter/sort")
                        Bullet("Tap **Share Award** to send to Messages or social")

                        Text("Medals personalize with your display name in **Settings → Profile**.")
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
                            .font(.subheadline)
                            .padding(.top, 4)
                        Bullet("Tap any \"Cycle X, Week Y\" header in History")
                        Bullet("See all lifts completed that week with AMRAP results")
                        Bullet("View total volume and best estimated 1RMs")
                        Bullet("Track progress trends across cycles")

                        Text("Find everything in **History** (top-left clock icon).")
                            .font(.footnote).foregroundStyle(.secondary)
                        Bullet("Tap an entry to expand notes; long-press for **Share summary** or **Delete**")
                        Bullet("Tap the week header icon for **Program Week Summary**; use **Share** on that screen")
                    }
                }

                // Data Management & Export
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Data Management & Export", systemImage: "externaldrive.fill")
                        Text("Backup, export, and manage all your workout data:")
                            .foregroundStyle(.primary)

                        Text("**Export Your Data:**")
                            .font(.subheadline)
                            .padding(.top, 4)
                        Bullet("**Export All Data (JSON):** Complete backup with all workouts, PRs, and metadata")
                        Bullet("**Export Workouts (CSV):** Open in Excel or Google Sheets for analysis")
                        Bullet("**Export PRs (CSV):** Track your progress over time in spreadsheets")

                        Text("**Manage Your Data:**")
                            .font(.subheadline)
                            .padding(.top, 8)
                        Bullet("**View All Workouts:** Search and filter your complete workout history")
                        Bullet("**View Workout Details:** See full breakdown of any past workout")
                        Bullet("**Delete Workouts:** Remove individual entries with confirmation")
                        Bullet("**View All PRs:** See personal records by lift and by cycle")
                        Bullet("**Storage Stats:** Monitor how much space your data uses")

                        Text("**Where to Find It:**")
                            .font(.subheadline)
                            .padding(.top, 8)
                        Text("Tap the **Data** icon (📂) in the top-left corner of the main screen, next to History.")
                            .font(.footnote).foregroundStyle(.secondary)

                        Text("**Why Export?**")
                            .font(.subheadline)
                            .padding(.top, 8)
                        Bullet("Create backups before major iOS updates")
                        Bullet("Analyze your progress in spreadsheet apps")
                        Bullet("Keep a copy for your records")
                        Bullet("Switch devices or apps with your data intact")

                        Text("All exports include timestamps and can be imported back into the app (JSON format only).")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // Sharing
                GuideCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Sharing", systemImage: "square.and.arrow.up")
                        Text("Share your progress straight from Beyond Normal.")
                            .foregroundStyle(.primary)

                        FeatureRow("Daily summaries", "Long-press a history entry → **Share summary**.", "doc.text")
                        FeatureRow("Weekly summaries", "Open **Program Week Summary** → **Share**.", "calendar.badge.checkmark")
                        FeatureRow("Awards", "Open any medal → **Share Award** to send the image + text.", "rosette")

                        Text("iMessage receives rich text that always renders (no blank body issues).")
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
                            .font(.subheadline)
                            .padding(.top, 4)
                        Bullet("Safety Squat Bar: 75 lb (not 45)")
                        Bullet("EZ Curl Bar: 25 lb")
                        Bullet("Trap Bar: 60 lb")

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
                        Tip("Medal physics", "In Trophy Room medal detail view, **flick harder for faster spins** — the physics respond to your gesture velocity with realistic angular momentum.")
                        Tip("Cycle tracking", "Current cycle and week appear at top of main screen — manual override in Settings if needed.")
                        Tip("TM adjustments", "You can manually adjust any TM between cycles if auto-progression feels too aggressive or conservative.")
                    }
                }

                // FAQ
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
                            "Classic adds fixed amounts each cycle (+5/+10 lb). Auto uses your best AMRAP performance to set the new TM to 90% of your estimated 1RM, capped at +10/+20 to prevent overreaching. Beginners should use Classic.")
                        FAQ("Why didn't my TM auto-increase the full amount?",
                            "Auto progression is capped at +10 lb upper / +20 lb lower per cycle to prevent overreaching. If your AMRAP suggested a bigger jump, it's intentionally limited for sustainable progress.")
                        FAQ("How do Awards work?",
                            "Awards are automatically generated when you set a new all-time PR (personal record) based on your estimated 1RM from AMRAP performance. They're stored in your Trophy Room, accessible from PRs & Awards.")
                        FAQ("Can I use different bars for different lifts?",
                            "Yes! Configure per-exercise bar weights in Settings → Implements. This affects plate math, warmup guidance, and weight displays. Great for specialty bars like SSB, trap bar, or EZ curl bar.")
                        FAQ("What happens during deload week?",
                            "Week 4 is your deload — a built-in recovery phase. You'll use lighter weights (40–60% TM), lower volume, and skip BBB/assistance work so your body can heal and adapt. Focus this week on sleep, nutrition, stress management, and gentle movement — light cardio, walks, mobility work.")
                        FAQ("How do I share a workout or week?",
                            "Long-press a history entry and choose **Share summary**. For weeks, open **Program Week Summary** and tap **Share** in the top-right.")
                        FAQ("Why does Messages show a subject line sometimes?",
                            "If the subject field is enabled in your Messages settings, iOS will show a subject row. The content you share still appears in the body so recipients always see it.")
                        FAQ("How do I backup my data?",
                            "Tap **Data** (📂 icon) in the top-left → **Export All Data (JSON)**. Save the file to iCloud Drive or Files app.")
                        FAQ("Can I view my data in Excel?",
                            "Yes! Tap **Data** → **Export Workouts (CSV)** or **Export PRs (CSV)** and open in Excel, Numbers, or Google Sheets.")
                        FAQ("How do I delete a single workout?",
                            "Tap **Data** → **View All Workouts** → tap the workout → **Delete Workout**. Or swipe left on any workout in History and tap Delete.")
                        FAQ("What happens to my data if I delete the app?",
                            "All local data is deleted. Export your data regularly to Files or iCloud for safekeeping.")
                        FAQ("How much storage does my data use?",
                            "Tap **Data** to see storage statistics at the top. Typical usage: ~1KB per workout, so even 1,000 workouts ≈ ~1MB.")
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
            .frame(maxWidth: 700)
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .navigationTitle("User Guide")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .opacity(isPresentedModally ? 1 : 0)
                    .accessibilityHidden(!isPresentedModally)
            }
        }
    }

    // Detect if the view is presented modally (best effort).
    private var isPresentedModally: Bool {
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
                colors: [Color(hex: "e55722").opacity(0.22), Color(hex: "2c7f7a").opacity(0.16)],
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
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.quaternary, lineWidth: 1)
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
            Text(.init(title)).font(.subheadline.weight(.semibold))
            if let detail = detail {
                Text(.init(detail)).font(.footnote).foregroundStyle(.secondary)
            }
        }
        Spacer()
    }
}

private func FeatureRow(_ title: String, _ subtitle: String, _ symbol: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
        Image(systemName: symbol).imageScale(.large)
        VStack(alignment: .leading, spacing: 2) {
            Text(.init(title)).font(.subheadline.weight(.semibold))
            Text(.init(subtitle)).font(.footnote).foregroundStyle(.secondary)
        }
        Spacer()
    }
}

private func Bullet(_ text: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
        Image(systemName: "circle.fill").font(.system(size: 6))
        Text(.init(text)).font(.subheadline)
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
                Text(.init(title)).font(.subheadline.weight(.semibold))
                Text(.init(detail)).font(.footnote).foregroundStyle(.secondary)
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
            Text(.init(a)).font(.footnote).foregroundStyle(.secondary).padding(.top, 4)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "q.circle").imageScale(.medium)
                Text(.init(q)).font(.subheadline.weight(.semibold))
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
                    Text(.init(title)).font(.subheadline.weight(.semibold))
                    Text(.init(subtitle)).font(.footnote).foregroundStyle(.secondary)
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

