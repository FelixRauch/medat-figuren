#if canImport(SwiftUI)
import SwiftUI

/// Renders a single piece polygon, scaled to its parent geometry.
public struct ShapePathView: Shape {

    public let vertices: [NormalizedPoint]

    public init(vertices: [NormalizedPoint]) {
        self.vertices = vertices
    }

    public func path(in rect: CGRect) -> Path {
        guard !vertices.isEmpty else { return Path() }
        var path = Path()
        let first = vertices[0].toPoint(in: rect.size)
        path.move(to: CGPoint(x: first.x + rect.minX, y: first.y + rect.minY))
        for pt in vertices.dropFirst() {
            let p = pt.toPoint(in: rect.size)
            path.addLine(to: CGPoint(x: p.x + rect.minX, y: p.y + rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

/// Renders the target shape outline.
/// Uses a native Circle() when shape.isCircle = true for pixel-perfect rendering.
public struct TargetShapeView: View {

    public let shape: PuzzleShape
    public var fillColor: Color = .indigo.opacity(0.12)
    public var strokeColor: Color = .indigo
    public var lineWidth: CGFloat = 2

    public init(shape: PuzzleShape,
                fillColor: Color = .indigo.opacity(0.12),
                strokeColor: Color = .indigo,
                lineWidth: CGFloat = 2) {
        self.shape = shape
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }

    public var body: some View {
        if shape.isCircle {
            Circle()
                .fill(fillColor)
                .overlay(Circle().stroke(strokeColor, lineWidth: lineWidth))
        } else {
            ShapePathView(vertices: shape.outline)
                .fill(fillColor)
                .overlay(
                    ShapePathView(vertices: shape.outline)
                        .stroke(strokeColor, lineWidth: lineWidth)
                )
        }
    }
}

/// Renders a single puzzle piece using its polygon vertices.
/// The sphere's pie slices use 24-point polygon arcs which are smooth enough
/// without needing a special arc path (which caused a 3/4-circle rendering bug).
public struct PieceShapeView: View {
    public let piece: ShapePiece
    public var fillColor: Color = .indigo.opacity(0.5)
    public var strokeColor: Color = .indigo.opacity(0.8)
    public var lineWidth: CGFloat = 1.5

    public init(piece: ShapePiece,
                fillColor: Color = .indigo.opacity(0.5),
                strokeColor: Color = .indigo.opacity(0.8),
                lineWidth: CGFloat = 1.5) {
        self.piece = piece
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ShapePathView(vertices: piece.vertices)
            .fill(fillColor)
            .overlay(
                ShapePathView(vertices: piece.vertices)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
    }
}

#endif // canImport(SwiftUI)
