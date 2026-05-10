#if canImport(SwiftUI)
import SwiftUI

/// Countdown timer bar for timed phases (4 & 5).
public struct TimerBarView: View {

    public let remaining: TimeInterval
    public let total: TimeInterval

    private var fraction: Double {
        guard total > 0 else { return 1 }
        return max(0, min(1, remaining / total))
    }

    private var timerColor: Color {
        if fraction > 0.5 { return .green }
        if fraction > 0.25 { return .orange }
        return .red
    }

    public init(remaining: TimeInterval, total: TimeInterval) {
        self.remaining = remaining
        self.total = total
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(String(format: "%.0fs", max(0, remaining)))
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(timerColor)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(timerColor)
                        .frame(width: geo.size.width * fraction)
                        .animation(.linear(duration: 0.1), value: fraction)
                }
            }
            .frame(height: 6)
        }
        .accessibilityLabel("Time remaining: \(Int(remaining)) seconds")
    }
}

#endif // canImport(SwiftUI)
