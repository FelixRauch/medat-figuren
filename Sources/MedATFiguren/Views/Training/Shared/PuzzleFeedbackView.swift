#if canImport(SwiftUI)
import SwiftUI

/// Feedback banner shown immediately after a puzzle attempt.
public struct PuzzleFeedbackView: View {

    public let isCorrect: Bool
    public let onContinue: () -> Void

    @State private var appeared = false

    public init(isCorrect: Bool, onContinue: @escaping () -> Void) {
        self.isCorrect = isCorrect
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: 32) {
            Spacer()

            iconView
                .scaleEffect(appeared ? 1 : 0.4)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.largeTitle.bold())
                Text(isCorrect
                     ? "Well done — your spatial reasoning is improving."
                     : "Don't worry — every attempt strengthens your understanding.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(isCorrect ? .green : .indigo)
            .accessibilityLabel("Continue to next puzzle")

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                appeared = true
            }
        }
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(isCorrect ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .frame(width: 120, height: 120)
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(isCorrect ? .green : .orange)
        }
    }
}

#endif // canImport(SwiftUI)
