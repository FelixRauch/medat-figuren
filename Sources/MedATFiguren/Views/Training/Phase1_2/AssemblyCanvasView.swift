#if canImport(SwiftUI)
import SwiftUI

// MARK: - Assembly canvas (Phases 1 & 2)

public struct AssemblyCanvasView: View {

    public let puzzle: Puzzle
    @Bindable public var vm: PuzzleViewModel
    @Environment(AppEnvironment.self) private var env

    @State private var selectedID: String? = nil
    @State private var selectionTick = 0

    // Lifted state — keyed by piece.id
    @State private var positions: [String: CGPoint] = [:]
    @State private var rotations: [String: Angle] = [:]
    // Position at the start of each drag gesture (so cumulative translation is safe)
    @State private var dragAnchors: [String: CGPoint] = [:]

    // Canvas-level rotation (two fingers anywhere = rotate selected piece)
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

    // MARK: - Canvas rotate gesture (canvas-wide, rotates selected piece)

    private var canvasRotateGesture: some Gesture {
        RotateGesture(minimumAngleDelta: .degrees(1))
            .updating($liveRotation) { value, state, _ in
                state = value.rotation
            }
            .onEnded { value in
                if let id = selectedID {
                    rotations[id, default: .zero] += value.rotation
                }
            }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func canvas(in size: CGSize) -> some View {
        ZStack(alignment: .topTrailing) {
            background
            pieceViews(in: size)
            hintCard
                .padding(.top, 16)
                .padding(.trailing, 16)
                .allowsHitTesting(false)
        }
    }

    private var background: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
                .onTapGesture { selectedID = nil }
            CanvasGridView().ignoresSafeArea().opacity(0.3).allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func pieceViews(in size: CGSize) -> some View {
        let items = puzzle.assemblyPieces ?? []
        ForEach(Array(items.enumerated()), id: \.element.id) { idx, piece in
            let start = startPosition(index: idx, total: items.count, in: size)
            let pos = positions[piece.id] ?? start
            let rot = rotations[piece.id, default: .zero]
                    + (selectedID == piece.id ? liveRotation : .zero)
            let selected = selectedID == piece.id

            CanvasPieceView(
                piece: piece,
                showEdgeHighlight: puzzle.phase.showsEdgeHighlighting,
                position: pos,
                rotation: rot,
                isSelected: selected,
                onDragStart: {
                    // Snapshot position when finger first touches
                    if selectedID != piece.id {
                        selectedID = piece.id
                        selectionTick += 1
                    }
                    dragAnchors[piece.id] = positions[piece.id] ?? start
                },
                onDrag: { translation in
                    // Always anchor + cumulative translation — no double-counting
                    let anchor = dragAnchors[piece.id] ?? (positions[piece.id] ?? start)
                    positions[piece.id] = CGPoint(
                        x: anchor.x + translation.width,
                        y: anchor.y + translation.height
                    )
                },
                onTap: {
                    if selectedID == piece.id { selectedID = nil }
                    else { selectedID = piece.id; selectionTick += 1 }
                },
                onReset: {
                    positions[piece.id] = start
                    rotations[piece.id] = .zero
                },
                onDoubleTap: {
                    rotations[piece.id, default: .zero] += .degrees(45)
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
            Label(
                selectedID != nil ? "Twist anywhere to rotate" : "Touch a piece to move it",
                systemImage: selectedID != nil ? "rotate.right" : "hand.point.up.left.fill"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
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
            .frame(width: 64, height: 64)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.10), radius: 8, y: 2)
    }

    // MARK: - Helpers

    private func startPosition(index: Int, total: Int, in size: CGSize) -> CGPoint {
        let pieceSize: CGFloat = 100
        let spacing: CGFloat = 20
        let total = CGFloat(total)
        let totalWidth = total * pieceSize + (total - 1) * spacing
        let startX = max(pieceSize / 2, (size.width - totalWidth) / 2 + pieceSize / 2)
        return CGPoint(
            x: startX + CGFloat(index) * (pieceSize + spacing),
            y: size.height * 0.72
        )
    }
}

// MARK: - CanvasPieceView

/// Stateless piece view — all position/rotation state lives in the parent canvas.
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

    // Live drag offset — @GestureState resets automatically on end
    @GestureState private var dragTranslation = CGSize.zero
    @GestureState private var isDragging = false
    @State private var dragStarted = false

    private let size: CGFloat = 100

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragTranslation) { value, state, _ in state = value.translation }
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                if !dragStarted {
                    dragStarted = true
                    onDragStart()
                }
                onDrag(value.translation)
            }
            .onEnded { _ in
                dragStarted = false
            }
    }

    var body: some View {
        ZStack {
            // Selection ring
            if isSelected {
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [.indigo, .cyan],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .frame(width: size + 20, height: size + 20)
                    .shadow(color: .indigo.opacity(0.45), radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }

            // Piece shape
            PieceShapeView(
                piece: piece,
                fillColor: isSelected
                    ? Color.indigo.opacity(isDragging ? 0.72 : 0.58)
                    : Color.indigo.opacity(0.32),
                strokeColor: showEdgeHighlight ? .yellow
                    : (isSelected ? .indigo : .indigo.opacity(0.55)),
                lineWidth: isSelected ? 2 : 1.5
            )
            .frame(width: size, height: size)
            .shadow(color: isSelected ? .indigo.opacity(0.25) : .clear,
                    radius: isDragging ? 18 : 8)

            // Reset button — top-right corner of piece, only when selected
            if isSelected {
                Button(action: onReset) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Circle().fill(.indigo))
                }
                .offset(x: size / 2 - 12, y: -size / 2 + 12)
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .rotationEffect(rotation)
        .scaleEffect(isDragging ? 1.07 : (isSelected ? 1.03 : 1.0))
        .position(position)
        .zIndex(isSelected ? 999 : 0)
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isSelected)
        // Touch to drag (also selects immediately)
        .gesture(dragGesture)
        // Tap to toggle selection (fires when no significant drag occurred)
        .onTapGesture { onTap() }
        // Double-tap: +45° snap
        .onTapGesture(count: 2) { onDoubleTap() }
        .accessibilityLabel("Puzzle piece\(isSelected ? " — selected" : "")")
        .accessibilityHint(isSelected ? "Drag to move, twist anywhere to rotate." : "Touch to select and drag.")
    }
}

// MARK: - CanvasGridView

private struct CanvasGridView: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 32
            var x: CGFloat = spacing
            while x < size.width {
                var y: CGFloat = spacing
                while y < size.height {
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                        with: .color(.gray.opacity(0.4))
                    )
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

#endif // canImport(SwiftUI)
