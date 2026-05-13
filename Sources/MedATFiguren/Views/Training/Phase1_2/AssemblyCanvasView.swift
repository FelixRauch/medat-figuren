#if canImport(SwiftUI)
import SwiftUI

// MARK: - Assembly canvas (Phases 1 & 2)

public struct AssemblyCanvasView: View {

    public let puzzle: Puzzle
    @Bindable public var vm: PuzzleViewModel
    @Environment(AppEnvironment.self) private var env

    /// ID of the currently selected piece (nil = none).
    @State private var selectedID: UUID? = nil
    /// Haptic trigger
    @State private var selectionTick = 0

    public init(puzzle: Puzzle, vm: PuzzleViewModel) {
        self.puzzle = puzzle
        self.vm = vm
    }

    public var body: some View {
        GeometryReader { geo in
            canvas(in: geo.size)
        }
        .navigationTitle(puzzle.shape.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: selectionTick)
        .toolbar { toolbarContent }
    }

    @ViewBuilder
    private func canvas(in size: CGSize) -> some View {
        ZStack(alignment: .topTrailing) {
            background
            pieces(in: size)
            hintCard
                .padding(.top, 16)
                .padding(.trailing, 16)
                .allowsHitTesting(false)
        }
    }

    private var background: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
                .onTapGesture { selectedID = nil }
            CanvasGridView()
                .ignoresSafeArea()
                .opacity(0.3)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func pieces(in size: CGSize) -> some View {
        let items = puzzle.assemblyPieces ?? []
        ForEach(Array(items.enumerated()), id: \.element.id) { idx, piece in
            CanvasPieceView(
                piece: piece,
                showEdgeHighlight: puzzle.phase.showsEdgeHighlighting,
                startPosition: startPosition(index: idx, total: items.count, in: size),
                isSelected: selectedID == piece.id,
                onSelect: { selectPiece(piece.id) },
                onDeselect: { selectedID = nil }
            )
        }
    }

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
            instructionBadge
        }
    }

    private var instructionBadge: some View {
        let active = selectedID != nil
        return Label(
            active ? "Drag or twist to manipulate" : "Tap a piece to select",
            systemImage: active ? "hand.draw.fill" : "hand.tap.fill"
        )
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func selectPiece(_ id: UUID) {
        if selectedID == id {
            selectedID = nil
        } else {
            selectedID = id
            selectionTick += 1
        }
    }

    // MARK: Hint card

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

    // MARK: Initial positions

    private func startPosition(index: Int, total: Int, in size: CGSize) -> CGPoint {
        let pieceSize: CGFloat = 100
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(total) * pieceSize + CGFloat(total - 1) * spacing
        let startX = max(pieceSize / 2, (size.width - totalWidth) / 2 + pieceSize / 2)
        return CGPoint(
            x: startX + CGFloat(index) * (pieceSize + spacing),
            y: size.height * 0.75
        )
    }
}

// MARK: - CanvasPieceView

private struct CanvasPieceView: View {

    let piece: ShapePiece
    let showEdgeHighlight: Bool
    let startPosition: CGPoint
    let isSelected: Bool
    let onSelect: () -> Void
    let onDeselect: () -> Void

    @State private var position: CGPoint
    @State private var committedAngle = Angle.zero
    @GestureState private var dragOffset = CGSize.zero
    @GestureState private var gestureAngle = Angle.zero
    @GestureState private var isDragging = false

    init(piece: ShapePiece, showEdgeHighlight: Bool, startPosition: CGPoint,
         isSelected: Bool, onSelect: @escaping () -> Void, onDeselect: @escaping () -> Void) {
        self.piece = piece
        self.showEdgeHighlight = showEdgeHighlight
        self.startPosition = startPosition
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onDeselect = onDeselect
        _position = State(initialValue: startPosition)
    }

    private let size: CGFloat = 100

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .updating($dragOffset) { value, state, _ in state = value.translation }
            .updating($isDragging) { _, state, _ in state = true }
            .onEnded { value in
                position.x += value.translation.width
                position.y += value.translation.height
            }
    }

    private var rotateGesture: some Gesture {
        RotateGesture(minimumAngleDelta: .degrees(2))
            .updating($gestureAngle) { value, state, _ in state = value.rotation }
            .onEnded { value in committedAngle += value.rotation }
    }

    var body: some View {
        ZStack {
            // Selection glow ring
            if isSelected {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.indigo, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: size + 20, height: size + 20)
                    .shadow(color: .indigo.opacity(0.5), radius: 12)
                    .transition(.scale.combined(with: .opacity))
            }

            // The piece shape
            PieceShapeView(
                piece: piece,
                fillColor: isSelected
                    ? Color.indigo.opacity(isDragging ? 0.75 : 0.6)
                    : Color.indigo.opacity(0.35),
                strokeColor: showEdgeHighlight ? .yellow
                    : (isSelected ? .indigo : .indigo.opacity(0.6)),
                lineWidth: isSelected ? 2 : 1.5
            )
            .frame(width: size, height: size)
            .shadow(
                color: isSelected ? .indigo.opacity(isDragging ? 0.4 : 0.2) : .clear,
                radius: isDragging ? 16 : 8
            )

            // Reset button (only visible when selected)
            if isSelected {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        position = startPosition
                        committedAngle = .zero
                    }
                } label: {
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
        .rotationEffect(committedAngle + gestureAngle)
        .scaleEffect(isDragging ? 1.08 : (isSelected ? 1.03 : 1.0))
        .offset(dragOffset)
        .position(position)
        .zIndex(isSelected ? 999 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        .animation(.interactiveSpring(response: 0.18), value: isDragging)
        // Tap: select / deselect
        .onTapGesture { onSelect() }
        // Drag & rotate — only when selected
        .gesture(isSelected ? dragGesture : nil)
        .simultaneousGesture(isSelected ? rotateGesture : nil)
        // Double-tap: +45° snap (only when selected)
        .onTapGesture(count: 2) {
            guard isSelected else { return }
            withAnimation(.spring(response: 0.28)) {
                committedAngle += .degrees(45)
            }
        }
        .accessibilityLabel("Puzzle piece\(isSelected ? " (selected)" : "")")
        .accessibilityHint(isSelected
            ? "Drag to move. Twist with two fingers to rotate. Double-tap for 45° snap. Tap ↩ to reset."
            : "Tap to select.")
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
                        with: .color(.gray.opacity(0.45))
                    )
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

#endif // canImport(SwiftUI)
