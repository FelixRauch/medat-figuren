#if canImport(SwiftUI)
import SwiftUI

/// Assembly canvas for Phases 1 and 2.
///
/// Shows the target shape outline plus a tray of draggable pieces.
/// Snapping and edge highlighting are enabled per the current phase rules.
public struct AssemblyCanvasView: View {

    public let puzzle: Puzzle
    @Bindable public var vm: PuzzleViewModel

    @Environment(AppEnvironment.self) private var env

    public init(puzzle: Puzzle, vm: PuzzleViewModel) {
        self.puzzle = puzzle
        self.vm = vm
    }

    public var body: some View {
        GeometryReader { geo in
            VStack(spacing: 24) {
                phaseHeader

                // Target shape area
                targetArea(in: geo.size)

                Divider()

                // Piece tray
                piecesTray(canvasSize: geo.size)

                Spacer()

                if puzzle.phase.hintsAllowed {
                    hintButton
                }
            }
            .padding()
        }
    }

    // MARK: - Sub-views

    private var phaseHeader: some View {
        VStack(spacing: 4) {
            PhaseIndicatorView(phase: puzzle.phase)
            Text("Assemble the shape")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func targetArea(in size: CGSize) -> some View {
        let canvasEdge = min(size.width, size.height * 0.42)
        return ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))

            TargetShapeView(
                shape: puzzle.shape,
                strokeColor: puzzle.phase.showsEdgeHighlighting ? .yellow : .indigo
            )
            .padding(16)
        }
        .frame(width: canvasEdge, height: canvasEdge)
        .accessibilityLabel("Target shape: \(puzzle.shape.name)")
    }

    private func piecesTray(canvasSize: CGSize) -> some View {
        let pieces = puzzle.assemblyPieces ?? []
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(pieces) { piece in
                    DraggablePieceView(
                        piece: piece,
                        canvasSize: canvasSize,
                        isPlaced: vm.correctlyPlacedIDs.contains(piece.id),
                        showEdgeHighlight: puzzle.phase.showsEdgeHighlighting,
                        onPlacedCorrectly: { vm.piecePlacedCorrectly(id: piece.id) }
                    )
                    .frame(width: 100, height: 100)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 130)
    }

    private var hintButton: some View {
        Button {
            vm.useHint()
        } label: {
            Label("Hint", systemImage: "lightbulb.fill")
                .font(.subheadline)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .accessibilityLabel("Use a hint")
    }
}

#endif // canImport(SwiftUI)
