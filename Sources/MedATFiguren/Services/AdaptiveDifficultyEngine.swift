import Foundation
import Observation

/// **Layer 2 — Adaptive Difficulty Engine.**
///
/// Continuously adjusts difficulty within the allowed envelope of the current phase.
///
/// Adjustment rules:
/// * Target success rate: **70–85 %** (optimal cognitive strain for learning).
/// * Performing well → increase AXIS B (ambiguity) first, then AXIS A (pieces).
/// * Struggling      → decrease AXIS B first, decrease AXIS A only if necessary.
/// * Engagement threatened → lower difficulty immediately, bypassing normal logic.
@Observable
public final class AdaptiveDifficultyEngine: Codable {

    // MARK: - Learning zone

    /// Lower bound of the target success rate zone.
    public static let targetLow: Double  = 0.70
    /// Upper bound of the target success rate zone.
    public static let targetHigh: Double = 0.85

    // MARK: - State

    public private(set) var currentDifficulty: DifficultyLevel
    private let phase: LearningPhase

    // MARK: - Tuning

    /// Minimum results required before making adjustments.
    private static let minSample = 5
    /// AXIS B step size per adjustment.
    private let ambiguityStep: Double = 0.05
    /// AXIS A step size per adjustment.
    private let pieceCountStep: Int = 1

    // MARK: - Init

    public init(phase: LearningPhase) {
        self.phase = phase
        self.currentDifficulty = phase.startingDifficulty
    }

    // MARK: - Public API

    /// Call after a batch of results to adjust difficulty.
    public func adjust(recentResults: [PuzzleResult], cognitiveModel: UserCognitiveModel) {
        guard recentResults.count >= Self.minSample else { return }

        let window = PerformanceWindow.compute(from: recentResults, weightedRecent: true)

        // Engagement protection overrides normal logic
        if cognitiveModel.isEngagementThreatened(successRate: window.successRate) {
            reduce()
            return
        }

        if window.successRate > Self.targetHigh {
            increase()
        } else if window.successRate < Self.targetLow {
            reduce()
        }
        // Within target zone: no change
    }

    // MARK: - Private

    private func increase() {
        let envelope = phase.difficultyEnvelope
        var next = currentDifficulty

        let newAmbiguity = next.ambiguity + ambiguityStep
        if newAmbiguity <= envelope.axisBRange.max {
            next.ambiguity = newAmbiguity
        } else if next.pieceCount < envelope.pieceCountRange.max {
            next.pieceCount += pieceCountStep
            next.ambiguity   = envelope.axisBRange.min  // reset B when A increases
        }

        currentDifficulty = next.clamped(to: envelope)
    }

    private func reduce() {
        let envelope = phase.difficultyEnvelope
        var next = currentDifficulty

        let newAmbiguity = next.ambiguity - ambiguityStep
        if newAmbiguity >= envelope.axisBRange.min {
            next.ambiguity = newAmbiguity
        } else if next.pieceCount > envelope.pieceCountRange.min {
            next.pieceCount -= pieceCountStep
            next.ambiguity   = envelope.axisBRange.max  // reset B when A decreases
        }

        currentDifficulty = next.clamped(to: envelope)
    }

    /// Resets difficulty to the starting point of a new phase.
    /// Call this after a phase transition.
    public func resetForPhase(_ newPhase: LearningPhase) {
        currentDifficulty = newPhase.startingDifficulty
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case currentDifficulty, phaseRawValue
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(currentDifficulty, forKey: .currentDifficulty)
        try c.encode(phase.rawValue, forKey: .phaseRawValue)
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentDifficulty = try c.decode(DifficultyLevel.self, forKey: .currentDifficulty)
        let raw = try c.decode(Int.self, forKey: .phaseRawValue)
        phase = LearningPhase(rawValue: raw) ?? .perceptualOnboarding
    }
}
