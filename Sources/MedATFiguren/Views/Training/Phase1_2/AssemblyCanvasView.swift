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
        self.puzzle = puzzle; self.vm = vm
    }

    public var body: some View {
        GeometryReader { geo in
            canvas(in: geo.size)
                .simultaneousGesture(canvasRotateGesture)
        }
        .navigationTitle(puzzle.shape.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: selectionTick)
        .toolbar { toolbarContent }
    }

    // MARK: - Rotation

    private var canvasRotateGesture: some Gesture {
        RotateGesture(minimumAngleDelta: .degrees(1))
            .updating($liveRotation) { value, state, _ in state = value.rotation }
            .onEnded { value in
                if let id = selectedID { rotations[id, default: .zero] += value.rotation }
            }
    }

    // MARK: - Canvas

    @ViewBuilder
    private func canvas(in size: CGSize) -> some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 0.11, green: 0.11, blue: 0.14).ignoresSafeArea()
                .onTapGesture { withAnimation(.snappy) { selectedID = nil } }
            CanvasGridView().ignoresSafeArea().allowsHitTesting(false)
            dropZoneIndicator(in: size).allowsHitTesting(false)
            pieceViews(in: size)
            hintCard.padding(.top, 16).padding(.trailing, 16).allowsHitTesting(false)
            VStack { Spacer(); submitButton(in: size).padding(.bottom, 32) }
        }
    }

    // MARK: - Drop zone

    private func dropZoneRect(in size: CGSize) -> CGRect {
        let w = size.width * 0.72
        let h = size.height * 0.52
        return CGRect(x: (size.width - w) / 2, y: size.height * 0.06, width: w, height: h)
    }

    @ViewBuilder
    private func dropZoneIndicator(in size: CGSize) -> some View {
        let r = dropZoneRect(in: size)
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
            .foregroundStyle(.white.opacity(0.1))
            .frame(width: r.width, height: r.height)
            .position(x: r.midX, y: r.midY)
    }

    // MARK: - Pieces

    private func pieceSize(in size: CGSize) -> CGFloat {
        min(size.width * 0.44, size.height * 0.34)
    }

    @ViewBuilder
    private func pieceViews(in size: CGSize) -> some View {
        let items = puzzle.assemblyPieces ?? []
        let ps = pieceSize(in: size)
        ForEach(Array(items.enumerated()), id: \.element.id) { idx, piece in
            let start = startPosition(index: idx, total: items.count, in: size, pieceSize: ps)
            let pos = positions[piece.id] ?? start
            let rot = rotations[piece.id, default: .zero]
                    + (selectedID == piece.id ? liveRotation : .zero)
            let sel = selectedID == piece.id
            CanvasPieceView(
                piece: piece, pieceSize: ps,
                showEdgeHighlight: puzzle.phase.showsEdgeHighlighting,
                position: pos, rotation: rot, isSelected: sel,
                onDragStart: {
                    if selectedID != piece.id {
                        withAnimation(.snappy) { selectedID = piece.id }
                        selectionTick += 1
                    }
                    dragAnchors[piece.id] = positions[piece.id] ?? start
                },
                onDrag: { t in
                    let anchor = dragAnchors[piece.id] ?? (positions[piece.id] ?? start)
                    positions[piece.id] = CGPoint(x: anchor.x + t.width, y: anchor.y + t.height)
                },
                onTap: {
                    withAnimation(.snappy) {
                        if selectedID == piece.id { selectedID = nil }
                        else { selectedID = piece.id; selectionTick += 1 }
                    }
                },
                onReset: { withAnimation(.bouncy) { positions[piece.id] = start; rotations[piece.id] = .zero } },
                onDoubleTap: { withAnimation(.snappy) { rotations[piece.id, default: .zero] += .degrees(45) } }
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if puzzle.phase.hintsAllowed {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { vm.useHint() } label: { Label("Hint", systemImage: "lightbulb.fill") }
                    .tint(.orange)
            }
        }
        ToolbarItem(placement: .principal) {
            Text(selectedID != nil ? "Twist to rotate" : "Touch a piece")
                .font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Hint card

    private var hintCard: some View {
        VStack(spacing: 6) {
            Text("Target").font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.45))
            TargetShapeView(
                shape: puzzle.shape,
                fillColor: .white.opacity(0.05),
                strokeColor: puzzle.phase.showsEdgeHighlighting ? .yellow.opacity(0.8) : .white.opacity(0.35),
                lineWidth: 1.5
            )
            .frame(width: 60, height: 60)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Submit

    private func submitButton(in size: CGSize) -> some View {
        Button(action: { evaluateAndSubmit(in: size) }) {
            Label("Submit Assembly", systemImage: "checkmark.circle.fill")
                .font(.headline).foregroundStyle(.black)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(Capsule().fill(.white).shadow(color: .white.opacity(0.2), radius: 12, y: 4))
        }
        .buttonStyle(.plain)
    }

    /// Correct if every piece is inside the drop zone AND
    /// rotated within ±25° of its solution rotation.
    private func evaluateAndSubmit(in size: CGSize) {
        let items = puzzle.assemblyPieces ?? []
        let ps    = pieceSize(in: size)
        let zone  = dropZoneRect(in: size)
        let tol   = 25.0   // degrees

        let allCorrect = items.allSatisfy { piece in
            let start = startPosition(index: 0, total: items.count, in: size, pieceSize: ps)
            let pos   = positions[piece.id] ?? start
            guard zone.contains(pos) else { return false }

            let currentDeg  = rotations[piece.id, default: .zero].degrees
            let solutionDeg = piece.solutionRotation * 180 / .pi
            var diff = abs(currentDeg - solutionDeg).truncatingRemainder(dividingBy: 360)
            if diff > 180 { diff = 360 - diff }
            return diff <= tol
        }

        if allCorrect {
            for piece in items { vm.piecePlacedCorrectly(id: piece.id) }
        } else {
            vm.submitIncorrectAssembly()
        }
    }

    // MARK: - Helpers

    private func startPosition(index: Int, total: Int, in size: CGSize, pieceSize: CGFloat) -> CGPoint {
        let spacing: CGFloat = 16
        let n = CGFloat(total)
        let totalWidth = n * pieceSize + (n - 1) * spacing
        let startX = max(pieceSize / 2, (size.width - totalWidth) / 2 + pieceSize / 2)
        return CGPoint(x: startX + CGFloat(index) * (pieceSize + spacing), y: size.height * 0.80)
    }
}

// MARK: - CanvasPieceView

private struct CanvasPieceView: View {
    let piece: ShapePiece
    let pieceSize: CGFloat
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

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { v in
                if !dragStarted { dragStarted = true; onDragStart() }
                onDrag(v.translation)
            }
            .onEnded { _ in dragStarted = false }
    }

    var body: some View {
        ZStack {
            PieceShapeView(piece: piece, fillColor: pieceColor, strokeColor: strokeColor,
                           lineWidth: isSelected ? 1.5 : 1)
                .frame(width: pieceSize, height: pieceSize)

            if isSelected {
                Button(action: onReset) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black.opacity(0.6))
                        .padding(6)
                        .background(Circle().fill(.white.opacity(0.9)))
                }
                .offset(x: pieceSize / 2 - 18, y: -pieceSize / 2 + 18)
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .shadow(
            color: isSelected ? .white.opacity(isDragging ? 0.3 : 0.18) : .black.opacity(0.4),
            radius: isSelected ? 18 : 6, y: isSelected ? 4 : 3
        )
        .rotationEffect(rotation)
        .position(position)
        .zIndex(isSelected ? 999 : 0)
        .animation(.snappy, value: isSelected)
        .gesture(dragGesture)
        .onTapGesture { onTap() }
        .onTapGesture(count: 2) { onDoubleTap() }
    }

    private var pieceColor: Color {
        guard showEdgeHighlight else {
            return isSelected ? .white.opacity(0.95) : .white.opacity(0.78)
        }
        return isSelected ? Color(red: 1, green: 0.97, blue: 0.88) : Color(red: 0.96, green: 0.93, blue: 0.83)
    }

    private var strokeColor: Color {
        guard showEdgeHighlight else {
            return isSelected ? .white.opacity(0.6) : .white.opacity(0.25)
        }
        return .orange.opacity(isSelected ? 0.9 : 0.5)
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
                    ctx.fill(Path(ellipseIn: CGRect(x: x-1, y: y-1, width: 2, height: 2)),
                             with: .color(.white.opacity(0.06)))
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

#endif // canImport(SwiftUI)
