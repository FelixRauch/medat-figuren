#if canImport(SwiftUI)
import SwiftUI

public struct PhaseTransitionView: View {

    public let from: LearningPhase
    public let to: LearningPhase
    public let onContinue: () -> Void

    @State private var appeared = false

    public init(from: LearningPhase, to: LearningPhase, onContinue: @escaping () -> Void) {
        self.from = from; self.to = to; self.onContinue = onContinue
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Trophy
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(.indigo)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)
                    .padding(.top, 48)

                VStack(spacing: 6) {
                    Text("Phase Complete")
                        .font(.largeTitle.bold())
                    Text("You've mastered \(from.shortName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1 : 0)

                // Info card
                InfoCard(
                    icon: "info.circle.fill",
                    iconTint: .orange,
                    title: "Expect a temporary dip",
                    body: "A drop in accuracy when entering a new phase is normal — it reflects a shift in cognitive strategy, not added difficulty. The system adapts with you."
                )
                .opacity(appeared ? 1 : 0)

                // Next phase
                VStack(alignment: .leading, spacing: 10) {
                    Label("Up next", systemImage: "arrow.right.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(to.displayName)
                        .font(.headline)
                    Text(to.phaseDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
                .opacity(appeared ? 1 : 0)

                Button("Start \(to.shortName)") { onContinue() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.indigo)
                    .padding(.bottom, 40)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.5)) { appeared = true }
        }
    }
}

// MARK: - InfoCard

private struct InfoCard: View {
    let icon: String
    let iconTint: Color
    let title: String
    let body: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconTint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(iconTint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

#endif // canImport(SwiftUI)
