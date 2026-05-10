import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A point in normalized [0, 1] × [0, 1] coordinate space.
/// Used for all puzzle shape definitions so they scale to any canvas size.
public struct NormalizedPoint: Codable, Sendable, Equatable, Hashable {
    public let x: Double
    public let y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

#if canImport(CoreGraphics)
    public init(_ cgPoint: CGPoint) {
        x = cgPoint.x
        y = cgPoint.y
    }

    /// Scales to an actual canvas size.
    public func toPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }

    public var cgPoint: CGPoint { CGPoint(x: x, y: y) }
#endif
}
