#if canImport(SwiftUI)
import SwiftUI
import UIKit

// MARK: - Assembly canvas (Phases 1 & 2)

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
                // Background
                Color(.systemGray6).ignoresSafeArea()

                // Subtle grid hint
                CanvasGridView()
                    .ignoresSafeArea()
                    .opacity(0.35)

                // Pieces
                let pieces = puzzle.assemblyPieces ?? []
                ForEach(Array(pieces.enumerated()), id: \.element.id) { idx, piece in
                    CanvasPieceView(
                        piece: piece,
                        showEdgeHighlight: puzzle.phase.showsEdgeHighlighting,
                        startPosition: startPosition(index: idx, total: pieces.count, in: geo.size)
                    )
                }

                // Hint card — top-right corner, unobtrusive
                hintCard
                    .padding(.top, 16)
                    .padding(.trailing, 16)
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

    // MARK: - Hint card

    private var hintCard: some View {
        VStack(spacing: 4) {
            Text("Target")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            TargetShapeView(
                shape: puzzle.shape,
                fillColor: .indigo.opacity(0.08),
                strokeColor: puzzle.phase.showsEdgeHighlighting ? .yellow : .indigo.opacity(0.7),
                lineWidth: 1.5
            )
            .frame(width: 68, height: 68)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }

    // MARK: - Initial positions

    private func startPosition(index: Int, total: Int, in size: CGSize) -> CGPoint {
        let pieceSize: CGFloat = 100
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(total) * pieceSize + CGFloat(total - 1) * spacing
        let startX = max(pieceSize / 2, (size.width - totalWidth) / 2 + pieceSize / 2)
        let x = startX + CGFloat(index) * (pieceSize + spacing)
        let y = size.height * 0.78
        return CGPoint(x: x, y: y)
    }
}

// MARK: - CanvasPieceView

private struct CanvasPieceView: View {

    let piece: ShapePiece
    let showEdgeHighlight: Bool
    let startPosition: CGPoint

    // Persisted (survive gesture end)
    @State private var position: CGPoint
    @State private var committedAngle = Angle.zero

    // Transient — @GestureState auto-resets to initial value when gesture ends
    @GestureState private var dragOffset = CGSize.zero
    @GestureState private var gestureAngle = Angle.zero
    @GestureState private var isActive = false

    init(piece: ShapePiece, showEdgeHighlight: Bool, startPosition: CGPoint) {
        self.piece = piece
        self.showEdgeHighlight = showEdgeHighlight
        self.startPosition = startPosition
        _position = State(initialValue: startPosition)
    }

    private let size: CGFloat = 100

    // MARK: Gestures

    /// Primary drag — moves the piece by translation delta, not absolute position
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .updating($isActive) { _, state, _ in
                state = true
            }
            .onEnded { value in
                position.x += value.translation.width
                position.y += value.translation.height
            }
    }

    /// Rotation — uses modern RotateGesture (iOS 17+), attached via .simultaneousGesture
    /// so it fires alongside the drag gesture without conflict.
    private var rotateGesture: some Gesture {
        RotateGesture(minimumAngleDelta: .degrees(2))
            .updating($gestureAngle) { value, state, _ in
                state = value.rotation
            }
            .onEnded { value in
                committedAngle += value.rotation
            }
    }

    var body: some View {
        ZStack {
            // Piece shape
            PieceShapeView(
                piece: piece,
                fillColor: isActive ? .indigo.opacity(0.65) : .indigo.opacity(0.45),
                strokeColor: showEdgeHighlight ? .yellow : .indigo,
                lineWidth: showEdgeHighlight ? 2.5 : 1.5
            )
            .frame(width: size, height: size)

            // Reset button — small, bottom-right of piece
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    position = startPosition
                    committedAngle = .zero
                }
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Circle().fill(.indigo.opacity(0.75)))
            }
            .offset(x: size / 2 - 14, y: size / 2 - 14)
            .buttonStyle(.plain)
        }
        .rotationEffect(committedAngle + gestureAngle)
        .scaleEffect(isActive ? 1.06 : 1.0)
        .shadow(
            color: .black.opacity(isActive ? 0.25 : 0.08),
            radius: isActive ? 14 : 4,
            y: isActive ? 4 : 1
        )
        // Offset during drag (auto-resets via @GestureState), position is the committed center
        .offset(dragOffset)
        .position(position)
        .zIndex(isActive ? 999 : 0)
        // Primary gesture: drag
        .gesture(dragGesture)
        // Simultaneous gesture: rotate — fires alongside drag, no conflict
        .simultaneousGesture(rotateGesture)
        // Double-tap: +45° snap
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.28)) {
                committedAngle += .degrees(45)
            }
        }
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: isActive)
        .accessibilityLabel("Puzzle piece")
        .accessibilityHint("Drag to move. Twist with two fingers to rotate. Double-tap for 45° snap. Tap ↩ to reset.")
    }
}

// MARK: - CanvasGridView

private struct CanvasGridView: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 28
            var x: CGFloat = spacing
            while x < size.width {
                var y: CGFloat = spacing
                while y < size.height {
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                        with: .color(.gray.opacity(0.5))
                    )
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

#endif // canImport(SwiftUI)
