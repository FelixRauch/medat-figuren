#if canImport(SwiftUI)
import SwiftUI

// MARK: - Assembly canvas (Phases 1 & 2)

public struct AssemblyCanvasView: View {

    public let puzzle: Puzzle
    @Bindable public var vm: PuzzleViewModel
    @Environment(AppEnvironment.self) private var env

    @State private var selectedID: String? = nil
    @State private var selectionTick = 0
    @State private var positions: [String: CGPoint] = [:]
    @State private var rotations: [String: Angle] = [:]
    @State private var dragAnchors: [String: CGPoint] = [:]
    @GestureState private var liveRotation = Angle.zero

    public init(puzzle: Puzzle, vm: PuzzleViewModel) {
        self.puzzle = puzzle
        self.vm = vm
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            canvas(in: geo.size)
                // RotateGesture covers the entire canvas
                .simultaneousGesture(canvasRotateGesture)
        }
        .navigationTitle(puzzle.shape.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: selectionTick)
        .toolbar { toolbarContent }
    }

    // MARK: - Canvas-wide rotation

    private var canvasRotateGesture: some Gesture {
        RotateGesture(minimumAngleDelta: .degrees(1))
            .updating($liveRotation) { value, state, _ in state = value.rotation }
            .onEnded { value in
                if let id = selectedID { rotations[id, default: .zero] += value.rotation }
            }
    }

    // MARK: - Layout

    @ViewBuilder
    private func canvas(in size: CGSize) -> some View {
        ZStack(alignment: .topTrailing) {
            // Dark slate workspace
            Color(red: 0.11, green: 0.11, blue: 0.14)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.snappy) { selectedID = nil } }

            CanvasGridView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            pieceViews(in: size)

            hintCard
                .padding(.top, 16)
                .padding(.trailing, 16)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func pieceViews(in size: CGSize) -> some View {
        let items = puzzle.assemblyPieces ?? []
        ForEach(Array(items.enumerated()), id: \.element.id) { idx, piece in
            let start = startPosition(index: idx, total: items.count, in: size)
            let pos   = positions[piece.id] ?? start
            let rot   = rotations[piece.id, default: .zero]
                      + (selectedID == piece.id ? liveRotation : .zero)
            let sel   = selectedID == piece.id

            CanvasPieceView(
                piece: piece,
                showEdgeHighlight: puzzle.phase.showsEdgeHighlighting,
                position: pos,
                rotation: rot,
                isSelected: sel,
                onDragStart: {
                    if selectedID != piece.id {
                        withAnimation(.snappy) { selectedID = piece.id }
                        selectionTick += 1
                    }
                    dragAnchors[piece.id] = positions[piece.id] ?? start
                },
                onDrag: { translation in
                    let anchor = dragAnchors[piece.id] ?? (positions[piece.id] ?? start)
                    positions[piece.id] = CGPoint(
                        x: anchor.x + translation.width,
                        y: anchor.y + translation.height
                    )
                },
                onTap: {
                    withAnimation(.snappy) {
                        if selectedID == piece.id { selectedID = nil }
                        else { selectedID = piece.id; selectionTick += 1 }
                    }
                },
                onReset: {
                    withAnimation(.bouncy) {
                        positions[piece.id] = start
                        rotations[piece.id] = .zero
                    }
                },
                onDoubleTap: {
                    withAnimation(.snappy) {
                        rotations[piece.id, default: .zero] += .degrees(45)
                    }
                }
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if puzzle.phase.hintsAllowed {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { vm.useHint() } label: {
                    Label("Hint", systemImage: "lightbulb.fill")
                }
                .tint(.orange)
            }
        }
        ToolbarItem(placement: .principal) {
            Text(selectedID != nil ? "Twist to rotate" : "Touch a piece")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Hint card

    private var hintCard: some View {
        VStack(spacing: 6) {
            Text("Target")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
            TargetShapeView(
                shape: puzzle.shape,
                fillColor: .white.opacity(0.05),
                strokeColor: puzzle.phase.showsEdgeHighlighting
                    ? .yellow.opacity(0.8) : .white.opacity(0.35),
                lineWidth: 1.5
            )
            .frame(width: 60, height: 60)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Layout helpers

    private func startPosition(index: Int, total: Int, in size: CGSize) -> CGPoint {
        let pieceSize: CGFloat = 100
        let spacing: CGFloat   = 20
        let n          = CGFloat(total)
        let totalWidth = n * pieceSize + (n - 1) * spacing
        let startX     = max(pieceSize / 2, (size.width - totalWidth) / 2 + pieceSize / 2)
        return CGPoint(
            x: startX + CGFloat(index) * (pieceSize + spacing),
            y: size.height * 0.72
        )
    }
}

// MARK: - CanvasPieceView

private struct CanvasPieceView: View {

    let piece: ShapePiece
    let showEdgeHighlight: Bool
    let position: CGPoint
    let rotation: Angle
    let isSelected: Bool
    let onDragStart: () -> Void
    let onDrag: (CGSize) -> Void
    let onTap: () -> Void
    let onReset: () -> Void
    let onDoubleTap: () -> Void

    @GestureState private var isDragging = false
    @State private var dragStarted = false
    private let size: CGFloat = 100

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                if !dragStarted { dragStarted = true; onDragStart() }
                onDrag(value.translation)
            }
            .onEnded { _ in dragStarted = false }
    }

    var body: some View {
        ZStack {
            // Piece — white paper look on dark canvas
            PieceShapeView(
                piece: piece,
                fillColor: pieceColor,
                strokeColor: strokeColor,
                lineWidth: isSelected ? 1.5 : 1
            )
            .frame(width: size, height: size)

            // Reset button — only when selected
            if isSelected {
                Button(action: onReset) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black.opacity(0.6))
                        .padding(5)
                        .background(Circle().fill(.white.opacity(0.9)))
                }
                .offset(x: size / 2 - 14, y: -size / 2 + 14)
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .shadow(
            color: isSelected
                ? .white.opacity(isDragging ? 0.28 : 0.18)
                : .black.opacity(0.35),
            radius: isSelected ? (isDragging ? 22 : 14) : 6,
            y: isSelected ? 4 : 3
        )
        .scaleEffect(isDragging ? 1.08 : (isSelected ? 1.04 : 1.0))
        .rotationEffect(rotation)
        .position(position)
        .zIndex(isSelected ? 999 : 0)
        .animation(.snappy, value: isSelected)
        .gesture(dragGesture)
        .onTapGesture { onTap() }
        .onTapGesture(count: 2) { onDoubleTap() }
        .accessibilityLabel("Puzzle piece\(isSelected ? " — selected" : "")")
        .accessibilityHint(isSelected ? "Drag to move. Twist anywhere to rotate." : "Touch to select.")
    }

    private var pieceColor: Color {
        if showEdgeHighlight {
            return isSelected
                ? Color(red: 1, green: 0.97, blue: 0.88)   // warm selected
                : Color(red: 0.96, green: 0.93, blue: 0.83) // warm unselected
        }
        return isSelected
            ? .white.opacity(0.95)
            : .white.opacity(0.75)
    }

    private var strokeColor: Color {
        if showEdgeHighlight { return .orange.opacity(isSelected ? 0.9 : 0.5) }
        return isSelected
            ? .white.opacity(0.6)
            : .white.opacity(0.25)
    }
}

// MARK: - CanvasGridView

private struct CanvasGridView: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 36
            var x: CGFloat = spacing
            while x < size.width {
                var y: CGFloat = spacing
                while y < size.height {
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                        with: .color(.white.opacity(0.06))
                    )
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

#endif // canImport(SwiftUI)
