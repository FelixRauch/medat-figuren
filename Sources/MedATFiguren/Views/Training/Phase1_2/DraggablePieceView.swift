#if canImport(SwiftUI)
import SwiftUI

/// A single draggable puzzle piece for the assembly canvas (Phases 1–2).
public struct DraggablePieceView: View {

    public let piece: ShapePiece
    public let canvasSize: CGSize
    public var isPlaced: Bool
    public var showEdgeHighlight: Bool
    public var onPlacedCorrectly: (() -> Void)?

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0  // radians, displayed as angle
    @State private var isDragging: Bool = false

    private let pieceSize: CGFloat = 120
    private var fillColor: Color { isPlaced ? .green.opacity(0.4) : .indigo.opacity(0.5) }

    public init(piece: ShapePiece,
                canvasSize: CGSize,
                isPlaced: Bool = false,
                showEdgeHighlight: Bool = false,
                onPlacedCorrectly: (() -> Void)? = nil) {
        self.piece = piece
        self.canvasSize = canvasSize
        self.isPlaced = isPlaced
        self.showEdgeHighlight = showEdgeHighlight
        self.onPlacedCorrectly = onPlacedCorrectly
    }

    public var body: some View {
        ShapePathView(vertices: piece.vertices)
            .fill(fillColor)
            .overlay(
                ShapePathView(vertices: piece.vertices)
                    .stroke(showEdgeHighlight ? Color.yellow : Color.indigo.opacity(0.8),
                            lineWidth: showEdgeHighlight ? 3 : 1.5)
            )
            .frame(width: pieceSize, height: pieceSize)
            .rotationEffect(.radians(rotation))
            .scaleEffect(isDragging ? 1.08 : 1.0)
            .offset(offset)
            .shadow(radius: isDragging ? 8 : 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        offset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        checkPlacement(translation: value.translation)
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    rotation += .pi / 2
                }
            }
            .accessibilityLabel("Puzzle piece")
            .accessibilityHint("Double-tap to rotate. Drag to place.")
    }

    private func checkPlacement(translation: CGSize) {
        // Tolerance-based snap: if piece center is within tolerance of correct position,
        // snap it and mark as placed. In a full implementation this would compare
        // against canvas coordinate targets derived from the shape outline.
        let tolerance: CGFloat = 50
        let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
        if distance < tolerance {
            withAnimation(.spring(response: 0.2)) {
                offset = .zero
            }
            onPlacedCorrectly?()
        } else {
            withAnimation(.spring(response: 0.4)) {
                offset = .zero
            }
        }
    }
}

#endif // canImport(SwiftUI)
