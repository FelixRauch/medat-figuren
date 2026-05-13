#if canImport(SwiftUI)
import SwiftUI

public struct PhaseIntroView: View {

    public let phase: LearningPhase
    public let onBegin: () -> Void

    public init(phase: LearningPhase, onBegin: @escaping () -> Void) {
        self.phase = phase
        self.onBegin = onBegin
    }

    public var body: some View {
        List {
            // ── Hero ───────────────────────────────────────────────
            Section {
                VStack(spacing: 12) {
                    Image(systemName: phaseIcon)
                        .font(.system(size: 52))
                        .foregroundStyle(.indigo)
                        .padding(.top, 8)
                    Text(phase.displayName)
                        .font(.title2.bold())
                    Text(phase.phaseDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            // ── Cognitive mode ─────────────────────────────────────
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cognitive Mode").font(.caption).foregroundStyle(.secondary)
                        Text(phase.cognitiveMode).font(.subheadline.weight(.medium))
                    }
                } icon: {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.indigo)
                }
            }

            // ── How it works ───────────────────────────────────────
            Section("How it works") {
                rulesContent
            }

            // ── Begin ──────────────────────────────────────────────
            Section {
                Button(action: onBegin) {
                    Label("Begin \(phase.shortName)", systemImage: "play.fill")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.indigo)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(phase.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var rulesContent: some View {
        switch phase {
        case .perceptualOnboarding:
            RuleRow("Touch a piece to select and drag it", icon: "hand.draw.fill")
            RuleRow("Two-finger twist anywhere to rotate", icon: "rotate.right.fill")
            RuleRow("Edge highlighting shows piece orientation", icon: "sparkles")
        case .structuredDecomposition:
            RuleRow("Drag pieces — snap-assist is reduced", icon: "hand.draw.fill")
            RuleRow("No edge highlighting this time", icon: "eye.slash.fill")
            RuleRow("Feedback shown after each puzzle", icon: "checkmark.seal.fill")
        case .mentalPrediction:
            RuleRow("Predict each piece's orientation first", icon: "brain.head.profile")
            RuleRow("Confirm by assembling — no hints", icon: "checkmark.circle")
            RuleRow("No edge guides or assistance", icon: "nosign")
        case .examSimulation:
            RuleRow("Pick the correct option from 4 choices", icon: "list.bullet")
            RuleRow("45-second time limit per puzzle", icon: "timer")
            RuleRow("Exam conditions — no hints", icon: "graduationcap.fill")
        case .mastery:
            RuleRow("Multiple choice, 25-second limit", icon: "bolt.fill")
            RuleRow("Maximum difficulty, 5–6 pieces", icon: "waveform.path.ecg")
            RuleRow("Build near-automatic spatial reasoning", icon: "star.fill")
        }
    }

    private var phaseIcon: String {
        switch phase {
        case .perceptualOnboarding:    return "puzzlepiece.fill"
        case .structuredDecomposition: return "square.grid.3x3.fill"
        case .mentalPrediction:        return "brain.head.profile"
        case .examSimulation:          return "graduationcap.fill"
        case .mastery:                 return "star.fill"
        }
    }
}

private struct RuleRow: View {
    let text: String
    let icon: String
    init(_ text: String, icon: String) { self.text = text; self.icon = icon }

    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
    }
}

#endif // canImport(SwiftUI)
