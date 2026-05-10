#if canImport(SwiftUI)
import SwiftUI

/// Minimal settings screen.
public struct SettingsView: View {

    public init() {}

    @State private var soundEnabled = true
    @State private var hapticEnabled = true

    public var body: some View {
        NavigationStack {
            Form {
                Section("Feedback") {
                    Toggle("Sound Effects", isOn: $soundEnabled)
                    Toggle("Haptic Feedback", isOn: $hapticEnabled)
                }

                Section("About") {
                    LabeledContent("App Version", value: Bundle.main.shortVersionString ?? "1.0")
                    LabeledContent("Training System", value: "MedAT Figuren zusammensetzen")
                    LabeledContent("Platform", value: "iOS / iPadOS 17+")
                }

                Section {
                    NavigationLink("Learning System Overview") {
                        LearningSystemOverviewView()
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(LearningPhase.allCases, id: \.rawValue) { phase in
                    VStack(alignment: .leading, spacing: 6) {
                        Label(phase.displayName, systemImage: "circle.fill")
                            .font(.headline)
                            .foregroundStyle(.indigo)
                        Text(phase.cognitiveMode)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(phase.phaseDescription)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
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
