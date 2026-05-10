#if canImport(SwiftUI)
import SwiftUI

// MARK: - Assembly canvas (Phases 1 & 2)
//
// Layout:
//   ┌─────────────────────────────┐
//   │  Phase header               │
//   │  ┌───────────────────────┐  │
//   │  │  Target shape outline │  │  ← drop / assemble area
//   │  └───────────────────────┘  │
//   │  ──────────────────────     │
//   │  [ piece ][ piece ][ … ]    │  ← tray (clips disabled so pieces
//   └─────────────────────────────┘      can escape while dragging)
//
// Pieces lift out of the tray and stay wherever the user drops them.
// Two-finger twist = continuous rotation.  Double-tap = +45° snap.

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
            VStack(spacing: 0) {

                // ── Phase header ────────────────────────────────────────
                VStack(spacing: 4) {
                    PhaseIndicatorView(phase: puzzle.phase)
                    Text("Assemble the shape")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)

                // ── Target / work area ──────────────────────────────────
                let canvasSize = min(geo.size.width - 32, geo.size.height * 0.46)
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                    TargetShapeView(
                        shape: puzzle.shape,
                        strokeColor: puzzle.phase.showsEdgeHighlighting ? .yellow : .indigo
                    )
                    .padding(20)
                }
                .frame(width: canvasSize, height: canvasSize)

                Divider().padding(.vertical, 10)

                // ── Piece tray ──────────────────────────────────────────
                // scrollClipDisabled() lets pieces visually escape the
                // tray bounds while being dragged upward.
                let pieces = puzzle.assemblyPieces ?? []
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(pieces) { piece in
                            TrayPieceView(
                                piece: piece,
                                showEdgeHighlight: puzzle.phase.showsEdgeHighlighting
                            )
                            .frame(width: 96, height: 96)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)  // vertical room so pieces escape upward
                }
                .scrollClipDisabled()
                .frame(maxHeight: 144)

                Spacer(minLength: 0)

                // ── Hint button ─────────────────────────────────────────
                if puzzle.phase.hintsAllowed {
                    Button { vm.useHint() } label: {
                        Label("Hint", systemImage: "lightbulb.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - TrayPieceView

/// A piece that starts in the tray and can be freely dragged anywhere on screen.
/// Supports simultaneous drag + two-finger rotation.  Double-tap snaps +45°.
private struct TrayPieceView: View {

    let piece: ShapePiece
    let showEdgeHighlight: Bool

    @State private var committedOffset: CGSize = .zero
    @State private var dragTranslation: CGSize = .zero
    @State private var rotation: Double = 0         // accumulated radians
    @State private var gestureRotation: Double = 0  // live delta from current gesture
    @State private var isDragging = false
    @State private var isRotating = false

    private var currentOffset: CGSize {
        CGSize(width:  committedOffset.width  + dragTranslation.width,
               height: committedOffset.height + dragTranslation.height)
    }

    // Combine drag + rotation simultaneously so both work with multiple fingers
    private var combinedGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .simultaneously(with: RotationGesture())
            .onChanged { value in
                if let drag = value.first {
                    isDragging = true
                    dragTranslation = drag.translation
                }
                if let rot = value.second {
                    isRotating = true
                    gestureRotation = rot.radians
                }
            }
            .onEnded { value in
                if let drag = value.first {
                    committedOffset = CGSize(
                        width:  committedOffset.width  + drag.translation.width,
                        height: committedOffset.height + drag.translation.height
                    )
                    dragTranslation = .zero
                    isDragging = false
                }
                if let rot = value.second {
                    rotation += rot.radians
                    gestureRotation = 0
                    isRotating = false
                }
            }
    }

    var body: some View {
        PieceShapeView(
            piece: piece,
            fillColor: .indigo.opacity(0.5),
            strokeColor: showEdgeHighlight ? .yellow : .indigo.opacity(0.85),
            lineWidth: showEdgeHighlight ? 3 : 1.5
        )
        .rotationEffect(.radians(rotation + gestureRotation))
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .shadow(color: .black.opacity(isDragging || isRotating ? 0.2 : 0.06),
                radius: isDragging || isRotating ? 10 : 3)
        .offset(currentOffset)
        .zIndex(isDragging || isRotating ? 999 : 0)
        .gesture(combinedGesture)
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.28)) {
                rotation += .pi / 4
            }
        }
        .accessibilityLabel("Puzzle piece — \(piece.id)")
        .accessibilityHint("Drag to move. Twist with two fingers to rotate. Double-tap to snap 45°.")
        .animation(.spring(response: 0.22), value: isDragging)
    }
}

#endif // canImport(SwiftUI)
