#if canImport(SwiftUI)
import SwiftUI

/// A compact phase badge shown in navigation toolbars and puzzle headers.
public struct PhaseIndicatorView: View {

    public let phase: LearningPhase

    public init(phase: LearningPhase) {
        self.phase = phase
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)
            Text("Phase \(phase.rawValue)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(phaseColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(phaseColor.opacity(0.1), in: Capsule())
        .accessibilityLabel(phase.displayName)
    }

    private var phaseColor: Color {
        switch phase {
        case .perceptualOnboarding:    return .blue
        case .structuredDecomposition: return .teal
        case .mentalPrediction:        return .indigo
        case .examSimulation:          return .orange
        case .mastery:                 return .purple
        }
    }
}

#endif // canImport(SwiftUI)
