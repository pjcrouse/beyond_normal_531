// UI/Settings/SystemSoundPickerView.swift
import SwiftUI
import AudioToolbox

struct SystemSoundPickerView: View {
    @AppStorage(kTimerSystemSoundIDKey) private var selectedID: Int = kTimerSystemSoundIDDefault

    // Curate or expand as you like. You can also do Array(1000..<1350)
    private let candidates: [Int] =
        Array(1000...1034) + [1050, 1051, 1052, 1053, 1054, 1057, 1100, 1101, 1320, 1321, 1322, 1335]

    var body: some View {
        List {
            Section("Choose a sound") {
                ForEach(candidates, id: \.self) { id in
                    // Compute a friendly name per-row (keeps the type-checker happy)
                    let name = systemSoundNames[id] ?? "Unknown"

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                            Text("#\(id)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if id == selectedID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.accent)
                        }

                        Button {
                            AudioServicesPlaySystemSound(SystemSoundID(id)) // preview
                            print("🔊 Previewing system sound #\(id)")
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                        }
                        .buttonStyle(.borderless)
                        .padding(.leading, 8)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedID = id
                        AudioServicesPlaySystemSound(SystemSoundID(id))   // confirm ping
                        print("✅ Selected system sound #\(id)")
                    }
                }
            }

            Section {
                Button {
                    AudioServicesPlaySystemSound(SystemSoundID(selectedID))
                    print("🧪 Testing selected sound #\(selectedID)")
                } label: {
                    Label("Test Selected", systemImage: "play.circle.fill")
                }
            } footer: {
                Text("System sounds respect the device’s Silent switch.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Timer Sound")
        .navigationBarTitleDisplayMode(.inline)
    }
}
