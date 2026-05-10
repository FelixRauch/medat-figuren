#if canImport(SwiftUI)
import SwiftUI

/// Phases 4 & 5 — Multiple choice puzzle view.
///
/// Displays the target shape and 4 options (sets of pieces).
/// The user taps the option they believe assembles the target shape.
/// A countdown timer applies time pressure per the phase configuration.
public struct MultipleChoiceView: View {

    public let puzzle: Puzzle
    @Bindable public var vm: PuzzleViewModel

    @State private var timeRemaining: TimeInterval
    @State private var timerActive: Bool = true
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var options: [MultipleChoiceOption] {
        puzzle.multipleChoiceOptions ?? []
    }

    public init(puzzle: Puzzle, vm: PuzzleViewModel) {
        self.puzzle = puzzle
        self.vm = vm
        self._timeRemaining = State(initialValue: puzzle.phase.timeLimitSeconds)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                headerBar
                targetShapeCard
                optionsGrid
                Spacer()
            }
            .padding()
            .navigationTitle(puzzle.phase.shortName)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(timer) { _ in
            guard timerActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 0.1
            } else {
                timerActive = false
                vm.selectOption(index: -1)  // time expired → incorrect
            }
        }
    }

    // MARK: - Sub-views

    private var headerBar: some View {
        HStack {
            PhaseIndicatorView(phase: puzzle.phase)
            Spacer()
            TimerBarView(remaining: timeRemaining, total: puzzle.phase.timeLimitSeconds)
                .frame(width: 160)
        }
    }

    private var targetShapeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Which set of pieces forms this shape?")
                .font(.headline)
            TargetShapeView(shape: puzzle.shape)
                .frame(height: 200)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Target shape: \(puzzle.shape.name)")
        }
    }

    private var optionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                OptionCell(
                    index: index,
                    pieces: option.pieces,
                    isSelected: vm.selectedOptionIndex == index
                ) {
                    timerActive = false
                    vm.selectOption(index: index)
                }
            }
        }
    }
}

// MARK: - OptionCell

private struct OptionCell: View {
    let index: Int
    let pieces: [ShapePiece]
    let isSelected: Bool
    let onTap: () -> Void

    private let labels = ["A", "B", "C", "D", "E"]

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(labels[safe: index] ?? "\(index + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary)

                ZStack {
                    ForEach(pieces) { piece in
                        ShapePathView(vertices: piece.vertices)
                            .fill(Color.indigo.opacity(0.5))
                            .overlay(
                                ShapePathView(vertices: piece.vertices)
                                    .stroke(isSelected ? Color.white : Color.indigo, lineWidth: 1.5)
                            )
                    }
                }
                .frame(width: 120, height: 120)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.indigo : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Option \(labels[safe: index] ?? "\(index + 1)")")
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#endif // canImport(SwiftUI)
