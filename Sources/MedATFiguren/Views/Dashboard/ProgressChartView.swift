#if canImport(SwiftUI)
import SwiftUI

/// Bar chart showing correct/incorrect results over recent puzzles.
public struct ProgressChartView: View {

    public let results: [PuzzleResult]

    public init(results: [PuzzleResult]) {
        self.results = results
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(results) { result in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(result.isCorrect ? Color.green : Color.red.opacity(0.7))
                        .frame(width: 12, height: result.isCorrect ? 80 : 40)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottomLeading) {
            Text("Recent \(results.count) puzzles")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .offset(y: 16)
        }
        .padding(.bottom, 20)
    }
}

#endif // canImport(SwiftUI)
