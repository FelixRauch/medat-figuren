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
        ShapePathView(vertices: shape.outline)
            .fill(fillColor)
            .overlay(
                ShapePathView(vertices: shape.outline)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
    }
}

#endif // canImport(SwiftUI)
