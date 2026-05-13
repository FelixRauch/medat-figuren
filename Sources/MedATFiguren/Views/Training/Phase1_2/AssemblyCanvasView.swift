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
            .coordinateSpace(name: "canvas")
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

    @State private var position: CGPoint
    @State private var rotation: Double = 0       // committed radians
    @State private var liveRotation: Double = 0   // in-flight rotation delta
    @State private var isActive = false

    init(piece: ShapePiece, showEdgeHighlight: Bool, startPosition: CGPoint) {
        self.piece = piece
        self.showEdgeHighlight = showEdgeHighlight
        self.startPosition = startPosition
        _position = State(initialValue: startPosition)
    }

    private let size: CGFloat = 100

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
                    rotation = 0
                    liveRotation = 0
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
        .rotationEffect(.radians(rotation + liveRotation))
        .scaleEffect(isActive ? 1.06 : 1.0)
        .shadow(color: .black.opacity(isActive ? 0.25 : 0.08),
                radius: isActive ? 14 : 4, y: isActive ? 4 : 1)
        .position(position)
        .zIndex(isActive ? 999 : 0)
        .overlay(
            // UIKit gesture bridge — fills the piece frame, handles all gestures
            SimultaneousGestureOverlay(
                onMove: { delta in
                    isActive = true
                    position.x += delta.x
                    position.y += delta.y
                },
                onRotate: { delta in
                    liveRotation = delta
                },
                onEnd: { rotationDelta in
                    rotation += rotationDelta
                    liveRotation = 0
                    isActive = false
                }
            )
            .frame(width: size, height: size)
            // keep the overlay centred on the piece, accounting for its own rotation
            .rotationEffect(.radians(rotation + liveRotation))
        )
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.28)) {
                rotation += .pi / 4
            }
        }
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: isActive)
        .accessibilityLabel("Puzzle piece")
        .accessibilityHint("Drag to move. Twist with two fingers to rotate. Double-tap for 45° snap. Double-tap reset icon to return home.")
    }
}

// MARK: - SimultaneousGestureOverlay

/// A transparent UIView that hosts a UIPanGestureRecognizer and a
/// UIRotationGestureRecognizer configured to fire simultaneously.
private struct SimultaneousGestureOverlay: UIViewRepresentable {

    /// Called each frame during a pan with (dx, dy) incremental delta.
    var onMove: (CGPoint) -> Void
    /// Called each frame during rotation with total in-flight radians.
    var onRotate: (Double) -> Void
    /// Called when all fingers lift. `rotationDelta` is the total rotation to commit.
    var onEnd: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onMove: onMove, onRotate: onRotate, onEnd: onEnd)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.delegate = context.coordinator
        pan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(pan)

        let rotation = UIRotationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleRotation(_:))
        )
        rotation.delegate = context.coordinator
        view.addGestureRecognizer(rotation)

        context.coordinator.panRecognizer = pan
        context.coordinator.rotationRecognizer = rotation
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onMove = onMove
        context.coordinator.onRotate = onRotate
        context.coordinator.onEnd = onEnd
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var onMove: (CGPoint) -> Void
        var onRotate: (Double) -> Void
        var onEnd: (Double) -> Void

        weak var panRecognizer: UIPanGestureRecognizer?
        weak var rotationRecognizer: UIRotationGestureRecognizer?

        private var lastPanTranslation: CGPoint = .zero
        private var accumulatedRotation: Double = 0

        init(onMove: @escaping (CGPoint) -> Void,
             onRotate: @escaping (Double) -> Void,
             onEnd: @escaping (Double) -> Void) {
            self.onMove = onMove
            self.onRotate = onRotate
            self.onEnd = onEnd
        }

        // Allow pan and rotation to fire at the same time
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool { true }

        @objc func handlePan(_ gr: UIPanGestureRecognizer) {
            switch gr.state {
            case .began:
                lastPanTranslation = .zero
            case .changed:
                let t = gr.translation(in: gr.view?.superview)
                let delta = CGPoint(x: t.x - lastPanTranslation.x,
                                    y: t.y - lastPanTranslation.y)
                lastPanTranslation = t
                DispatchQueue.main.async { self.onMove(delta) }
            case .ended, .cancelled, .failed:
                lastPanTranslation = .zero
                checkEnd()
            default: break
            }
        }

        @objc func handleRotation(_ gr: UIRotationGestureRecognizer) {
            switch gr.state {
            case .began:
                accumulatedRotation = 0
            case .changed:
                accumulatedRotation = Double(gr.rotation)
                DispatchQueue.main.async { self.onRotate(self.accumulatedRotation) }
            case .ended, .cancelled, .failed:
                checkEnd()
            default: break
            }
        }

        private func checkEnd() {
            let panDone = panRecognizer.map {
                $0.state == .ended || $0.state == .cancelled || $0.state == .failed || $0.state == .possible
            } ?? true
            let rotDone = rotationRecognizer.map {
                $0.state == .ended || $0.state == .cancelled || $0.state == .failed || $0.state == .possible
            } ?? true
            if panDone && rotDone {
                let r = accumulatedRotation
                accumulatedRotation = 0
                DispatchQueue.main.async { self.onEnd(r) }
            }
        }
    }
}

// MARK: - CanvasGridView

/// Light dot-grid background to give the canvas a worksheet feel.
private struct CanvasGridView: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let spacing: CGFloat = 28
                var x: CGFloat = spacing
                while x < size.width {
                    var y: CGFloat = spacing
                    while y < size.height {
                        let dot = Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                        ctx.fill(dot, with: .color(.gray.opacity(0.5)))
                        y += spacing
                    }
                    x += spacing
                }
            }
        }
    }
}

#endif // canImport(SwiftUI)
