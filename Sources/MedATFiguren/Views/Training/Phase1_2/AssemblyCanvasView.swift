#if canImport(SwiftUI)
import SwiftUI

// MARK: - Worksheet canvas (Phases 1 & 2)
//
// The user sees a large free-form workspace.  A small "reference" card in the
// top-right corner shows the target shape they are trying to assemble.  All
// pieces are scattered randomly on the canvas and can be dragged freely and
// rotated with a two-finger rotation gesture (or double-tap for 45° snaps).

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
            ZStack(alignment: .topTrailing) {

                // ── Background ──────────────────────────────────────────
                Color(.systemGray6)
                    .ignoresSafeArea()

                // ── Pieces scattered freely on the canvas ────────────────
                let pieces = puzzle.assemblyPieces ?? []
                ForEach(Array(pieces.enumerated()), id: \.element.id) { index, piece in
                    FreePieceView(
                        piece: piece,
                        isCirclePuzzle: puzzle.shape.isCircle,
                        showEdgeHighlight: puzzle.phase.showsEdgeHighlighting,
                        initialOffset: scatterOffset(index: index,
                                                     total: pieces.count,
                                                     in: geo.size)
                    )
                }

                // ── Reference card (top-right) ───────────────────────────
                referenceCard
                    .padding(12)
            }
        }
        .navigationTitle(puzzle.shape.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if puzzle.phase.hintsAllowed {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { vm.useHint() } label: {
                        Label("Hint", systemImage: "lightbulb.fill")
                    }
                    .tint(.orange)
                }
            }
        }
    }

    // MARK: - Reference card

    private var referenceCard: some View {
        VStack(spacing: 4) {
            Text("Target")
                .font(.caption2)
                .foregroundStyle(.secondary)
            TargetShapeView(
                shape: puzzle.shape,
                strokeColor: puzzle.phase.showsEdgeHighlighting ? .yellow : .indigo
            )
            .frame(width: 90, height: 90)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
            )
        }
    }

    // MARK: - Scatter helper

    /// Distribute pieces in the lower 70% of the canvas in a loose grid.
    private func scatterOffset(index: Int, total: Int, in size: CGSize) -> CGSize {
        let cols = max(2, Int(ceil(sqrt(Double(total)))))
        let col  = index % cols
        let row  = index / cols
        let cellW = size.width  / CGFloat(cols)
        let cellH = (size.height * 0.65) / CGFloat(max(1, (total - 1) / cols + 1))
        let x = cellW * (CGFloat(col) + 0.5) - size.width  / 2
        let y = size.height * 0.28 + cellH * (CGFloat(row) + 0.5) - size.height / 2
        // Small random jitter so pieces don't sit in a rigid grid
        let jitter = CGFloat(16)
        let jx = CGFloat.random(in: -jitter...jitter)
        let jy = CGFloat.random(in: -jitter...jitter)
        return CGSize(width: x + jx, height: y + jy)
    }
}

// MARK: - FreePieceView

/// A puzzle piece that can be dragged anywhere on the canvas and rotated.
///
/// • **Drag** — move freely.
/// • **Two-finger rotate** — continuous rotation gesture.
/// • **Double-tap** — snap rotate by 45°.
private struct FreePieceView: View {

    let piece: ShapePiece
    let isCirclePuzzle: Bool
    let showEdgeHighlight: Bool
    let initialOffset: CGSize

    /// The last committed position (updated when a drag ends).
    @State private var committedOffset: CGSize
    /// Live offset = committedOffset + current drag translation.
    @State private var dragTranslation: CGSize = .zero
    @State private var rotation: Double = 0          // radians
    @State private var gestureRotation: Double = 0   // live delta while rotating
    @State private var isDragging = false
    @State private var isRotating = false

    private let size: CGFloat = 110

    private var offset: CGSize {
        CGSize(width: committedOffset.width  + dragTranslation.width,
               height: committedOffset.height + dragTranslation.height)
    }

    init(piece: ShapePiece,
         isCirclePuzzle: Bool,
         showEdgeHighlight: Bool,
         initialOffset: CGSize) {
        self.piece = piece
        self.isCirclePuzzle = isCirclePuzzle
        self.showEdgeHighlight = showEdgeHighlight
        self.initialOffset = initialOffset
        _committedOffset = State(initialValue: initialOffset)
    }

    var body: some View {
        PieceShapeView(
            piece: piece,
            isCirclePuzzle: isCirclePuzzle,
            fillColor: .indigo.opacity(0.45),
            strokeColor: showEdgeHighlight ? .yellow : .indigo.opacity(0.85),
            lineWidth: showEdgeHighlight ? 3 : 1.5
        )
        .frame(width: size, height: size)
        .rotationEffect(.radians(rotation + gestureRotation))
        .scaleEffect(isDragging ? 1.08 : 1.0)
        .shadow(color: .black.opacity(isDragging || isRotating ? 0.22 : 0.08),
                radius: isDragging || isRotating ? 10 : 3)
        .offset(offset)
        .zIndex(isDragging || isRotating ? 999 : 0)
        // Drag
        .gesture(
            DragGesture()
                .onChanged { v in
                    isDragging = true
                    dragTranslation = v.translation
                }
                .onEnded { v in
                    isDragging = false
                    committedOffset = CGSize(
                        width:  committedOffset.width  + v.translation.width,
                        height: committedOffset.height + v.translation.height
                    )
                    dragTranslation = .zero
                }
        )
        // Two-finger rotation
        .gesture(
            RotationGesture()
                .onChanged { angle in
                    isRotating = true
                    gestureRotation = angle.radians
                }
                .onEnded { angle in
                    rotation += angle.radians
                    gestureRotation = 0
                    isRotating = false
                }
        )
        // Double-tap: +45°
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.3)) {
                rotation += .pi / 4
            }
        }
        .accessibilityLabel("Puzzle piece")
        .accessibilityHint("Drag to move. Use two fingers to rotate, or double-tap for 45° snap.")
    }
}

#endif // canImport(SwiftUI)
