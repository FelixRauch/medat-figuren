#if canImport(SwiftUI)
import SwiftUI

/// Celebrates a phase transition and explains what changes cognitively.
public struct PhaseTransitionView: View {

    public let from: LearningPhase
    public let to: LearningPhase
    public let onContinue: () -> Void

    @State private var appeared = false

    public init(from: LearningPhase, to: LearningPhase, onContinue: @escaping () -> Void) {
        self.from = from
        self.to = to
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.indigo)
                .scaleEffect(appeared ? 1 : 0.3)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                Text("Phase Complete!")
                    .font(.largeTitle.bold())

                Text("You've mastered \(from.shortName).")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            regressionWarningCard

            VStack(alignment: .leading, spacing: 8) {
                Text("Next: \(to.displayName)")
                    .font(.headline)
                Text(to.phaseDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Button("Start \(to.shortName)") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.indigo)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    // MARK: - Regression warning

    private var regressionWarningCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Expect a temporary dip", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            Text("A temporary drop in accuracy when entering a new phase is **expected and normal**. It's caused by a change in cognitive strategy — not increased difficulty. The system will adapt with you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#endif // canImport(SwiftUI)
