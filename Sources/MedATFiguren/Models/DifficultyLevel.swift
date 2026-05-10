import Foundation

// MARK: - DifficultyLevel

/// Two-axis puzzle difficulty.
///
/// - **AXIS A** — Structural complexity: number of pieces (1–6).
/// - **AXIS B** — Cognitive ambiguity: 0.0 (trivial) → 1.0 (extreme).
///
/// The axes are *independent* and tuned separately by the adaptive engine.
public struct DifficultyLevel: Codable, Sendable, Equatable {

    /// AXIS A — structural load.
    public var pieceCount: Int

    /// AXIS B — cognitive ambiguity (0.0 – 1.0).
    public var ambiguity: Double

    public init(pieceCount: Int, ambiguity: Double) {
        self.pieceCount = pieceCount.clamped(to: 1...6)
        self.ambiguity = ambiguity.clamped(to: 0...1)
    }

    public static let minimal = DifficultyLevel(pieceCount: 1, ambiguity: 0.0)
    public static let maximum = DifficultyLevel(pieceCount: 6, ambiguity: 1.0)

    /// Composite score in [0, 1] for rough comparison (not used for adaptive logic).
    public var normalizedScore: Double {
        let pieceScore = Double(pieceCount - 1) / 5.0
        return (pieceScore + ambiguity) / 2.0
    }

    /// Whether this difficulty falls within the given envelope.
    public func isWithin(_ envelope: DifficultyEnvelope) -> Bool {
        (envelope.pieceCountRange.min...envelope.pieceCountRange.max).contains(pieceCount)
        && ambiguity >= envelope.axisBRange.min
        && ambiguity <= envelope.axisBRange.max
    }

    /// A copy clamped to the given envelope.
    public func clamped(to envelope: DifficultyEnvelope) -> DifficultyLevel {
        DifficultyLevel(
            pieceCount: pieceCount.clamped(
                to: envelope.pieceCountRange.min...envelope.pieceCountRange.max),
            ambiguity: ambiguity.clamped(
                to: envelope.axisBRange.min...envelope.axisBRange.max)
        )
    }
}

// MARK: - DifficultyEnvelope

/// The allowed difficulty window for a learning phase.
/// Defines min/max for both AXIS A and AXIS B.
public struct DifficultyEnvelope: Codable, Sendable, Equatable {
    public let axisBRange: AxisRange
    public let pieceCountRange: IntRange

    public init(axisBRange: (Double, Double), pieceCountRange: (Int, Int)) {
        self.axisBRange = AxisRange(min: axisBRange.0, max: axisBRange.1)
        self.pieceCountRange = IntRange(min: pieceCountRange.0, max: pieceCountRange.1)
    }

    /// Helper: closed range for AXIS B (ambiguity).
    public var axisBClosedRange: ClosedRange<Double> {
        axisBRange.min...axisBRange.max
    }
}

public struct AxisRange: Codable, Sendable, Equatable {
    public let min: Double
    public let max: Double
}

public struct IntRange: Codable, Sendable, Equatable {
    public let min: Int
    public let max: Int
}

// MARK: - Comparable helpers

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
