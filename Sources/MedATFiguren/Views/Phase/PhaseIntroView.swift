#if canImport(SwiftUI)
import SwiftUI

/// Introductory screen shown when a user reaches a new phase.
public struct PhaseIntroView: View {

    public let phase: LearningPhase
    public let onBegin: () -> Void

    public init(phase: LearningPhase, onBegin: @escaping () -> Void) {
        self.phase = phase
        self.onBegin = onBegin
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                phaseHeader
                cognitiveModeBanner
                rulesCard
                objectiveCard
                beginButton
            }
            .padding()
        }
        .navigationTitle(phase.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sub-views

    private var phaseHeader: some View {
        VStack(spacing: 6) {
            Image(systemName: phaseIcon)
                .font(.system(size: 56))
                .foregroundStyle(.indigo)
                .padding(.top, 8)
            Text(phase.displayName)
                .font(.title.bold())
            Text(phase.phaseDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var cognitiveModeBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cognitive Mode")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(phase.cognitiveMode)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How it works")
                .font(.headline)

            rulesContent
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var rulesContent: some View {
        switch phase {
        case .perceptualOnboarding:
            ruleRow("Drag and drop pieces onto the canvas", icon: "hand.draw.fill")
            ruleRow("Double-tap a piece to rotate it", icon: "rotate.right.fill")
            ruleRow("Edge highlighting shows where pieces fit", icon: "sparkles")
        case .structuredDecomposition:
            ruleRow("Drag and drop — snapping is reduced", icon: "hand.draw.fill")
            ruleRow("No edge highlighting this time", icon: "eye.slash.fill")
            ruleRow("You'll get feedback after completing each puzzle", icon: "checkmark.seal.fill")
        case .mentalPrediction:
            ruleRow("First: predict each piece's orientation", icon: "brain.head.profile")
            ruleRow("Then confirm — and verify by assembling", icon: "checkmark.circle")
            ruleRow("No hints or edge guides", icon: "nosign")
        case .examSimulation:
            ruleRow("Select the correct option from 4 choices", icon: "list.bullet")
            ruleRow("45-second time limit per puzzle", icon: "timer")
            ruleRow("No hints, no guidance — exam conditions", icon: "graduationcap.fill")
        case .mastery:
            ruleRow("Multiple choice under 25-second time limit", icon: "bolt.fill")
            ruleRow("Maximum difficulty: high ambiguity, 5–6 pieces", icon: "waveform.path.ecg")
            ruleRow("Develop near-automatic spatial reasoning", icon: "star.fill")
        }
    }

    private func ruleRow(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.primary)
    }

    private var objectiveCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Learning Objective")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(phase.phaseDescription)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var beginButton: some View {
        Button {
            onBegin()
        } label: {
            Label("Begin \(phase.shortName)", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.indigo)
        .padding(.bottom)
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

#endif // canImport(SwiftUI)
