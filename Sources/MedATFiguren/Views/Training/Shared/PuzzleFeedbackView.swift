#if canImport(SwiftUI)
import SwiftUI

public struct PuzzleFeedbackView: View {

    public let isCorrect: Bool
    public let onContinue: () -> Void

    @State private var appeared = false

    public init(isCorrect: Bool, onContinue: @escaping () -> Void) {
        self.isCorrect = isCorrect
        self.onContinue = onContinue
    }

    private var accent: Color { isCorrect ? .green : .orange }

    public var body: some View {
        ZStack {
            accent.opacity(0.04).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(accent)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .padding(.bottom, 28)

                // Headline
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.largeTitle.bold())
                    .opacity(appeared ? 1 : 0)

                Text(isCorrect
                     ? "Great work — your spatial reasoning is improving."
                     : "Every attempt builds stronger mental models.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(accent)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.45)) { appeared = true }
        }
    }
}

#endif // canImport(SwiftUI)
