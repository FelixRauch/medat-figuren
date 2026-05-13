#if canImport(SwiftUI)
import SwiftUI

public struct SettingsView: View {

    public init() {}

    @State private var soundEnabled = true
    @State private var hapticEnabled = true

    public var body: some View {
        NavigationStack {
            Form {
                // ── App icon / header ──────────────────────────────────
                Section {
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "puzzlepiece.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MedAT Figuren")
                                .font(.headline)
                            Text("Spatial reasoning trainer")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // ── Feedback ───────────────────────────────────────────
                Section("Feedback") {
                    Toggle(isOn: $soundEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                    }
                    Toggle(isOn: $hapticEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }
                }

                // ── Learn ──────────────────────────────────────────────
                Section("Learning System") {
                    NavigationLink {
                        LearningSystemOverviewView()
                    } label: {
                        Label("Phase Overview", systemImage: "brain.head.profile")
                    }
                }

                // ── About ──────────────────────────────────────────────
                Section("About") {
                    LabeledContent("Version") {
                        Text(Bundle.main.shortVersionString ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Training System") {
                        Text("Figuren zusammensetzen")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Learning system overview

private struct LearningSystemOverviewView: View {
    var body: some View {
        List {
            ForEach(LearningPhase.allCases, id: \.rawValue) { phase in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(phase.cognitiveMode, systemImage: "sparkles")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.indigo)
                        Text(phase.phaseDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label(phase.displayName, systemImage: "circle.fill")
                        .foregroundStyle(.indigo)
                }
            }
        }
        .navigationTitle("Learning System")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bundle helper

private extension Bundle {
    var shortVersionString: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

#endif // canImport(SwiftUI)
