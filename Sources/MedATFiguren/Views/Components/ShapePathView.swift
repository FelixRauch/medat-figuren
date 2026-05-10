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

/// Renders a single puzzle piece.
/// For circle pieces (pie slices) the vertices are used as-is (they are already smooth arcs
/// approximated with many points from the sphere() constructor).
public struct PieceShapeView: View {
    public let piece: ShapePiece
    public let isCirclePuzzle: Bool
    public var fillColor: Color = .indigo.opacity(0.5)
    public var strokeColor: Color = .indigo.opacity(0.8)
    public var lineWidth: CGFloat = 1.5

    public init(piece: ShapePiece,
                isCirclePuzzle: Bool = false,
                fillColor: Color = .indigo.opacity(0.5),
                strokeColor: Color = .indigo.opacity(0.8),
                lineWidth: CGFloat = 1.5) {
        self.piece = piece
        self.isCirclePuzzle = isCirclePuzzle
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }

    public var body: some View {
        GeometryReader { geo in
            let path = smoothPiecePath(in: geo.frame(in: .local))
            path
                .fill(fillColor)
                .overlay(path.stroke(strokeColor, lineWidth: lineWidth))
        }
    }

    private func smoothPiecePath(in rect: CGRect) -> Path {
        guard !piece.vertices.isEmpty else { return Path() }
        if isCirclePuzzle {
            // Build a path with a smooth circular arc for the outer edge.
            // Convention for sphere pieces: first vertex is the center (0.5, 0.5),
            // remaining vertices are the arc points. We close the pie with straight
            // lines to center and an arc between the first and last arc points.
            let verts = piece.vertices
            let center = verts[0].toPoint(in: rect.size)
            let cx = center.x + rect.minX
            let cy = center.y + rect.minY
            let arcPts = verts.dropFirst().map { v -> CGPoint in
                let p = v.toPoint(in: rect.size)
                return CGPoint(x: p.x + rect.minX, y: p.y + rect.minY)
            }
            guard let firstArc = arcPts.first, let lastArc = arcPts.last else {
                return ShapePathView(vertices: verts).path(in: rect)
            }
            let radius = hypot(firstArc.x - cx, firstArc.y - cy)
            let startAngle = atan2(firstArc.y - cy, firstArc.x - cx)
            let endAngle   = atan2(lastArc.y  - cy, lastArc.x  - cx)
            var path = Path()
            path.move(to: CGPoint(x: cx, y: cy))
            path.addLine(to: firstArc)
            path.addArc(center: CGPoint(x: cx, y: cy),
                        radius: radius,
                        startAngle: .radians(startAngle),
                        endAngle: .radians(endAngle),
                        clockwise: false)
            path.closeSubpath()
            return path
        } else {
            return ShapePathView(vertices: piece.vertices).path(in: rect)
        }
    }
}

#endif // canImport(SwiftUI)
