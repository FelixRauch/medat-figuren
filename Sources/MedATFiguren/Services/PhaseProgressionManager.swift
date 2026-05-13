import Foundation
import Observation

/// **Layer 1 — Phase Progression Manager.**
///
/// Enforces forward-only stage progression. Users advance when:
/// 1. They have attempted `minPuzzlesForAdvancement` puzzles in the current phase.
/// 2. The last `stabilityWindow` results yield a success rate ≥ `cognitiveModel.progressionThreshold`.
///
/// Stages **never** loop backward. Temporary regression after entering a new stage is
/// handled by the adaptive difficulty engine, not by reverting phases.
@Observable
public final class PhaseProgressionManager {

    // MARK: - Configuration

    /// Minimum attempts in a phase before advancement is evaluated.
    public static let minPuzzlesForAdvancement = 15
    /// Consecutive recent results examined for stability.
    public static let stabilityWindow = 10

    // MARK: - Observed State

    /// Whether the current state meets the criteria for advancing.
    public private(set) var isEligibleForTransition: Bool = false
    /// 0–1 confidence ratio (successRate / progressionThreshold).
    public private(set) var transitionConfidence: Double = 0

    // MARK: - Dependencies

    private let progress: UserProgress
    private let cognitiveModel: UserCognitiveModel

    // MARK: - Init

    public init(progress: UserProgress, cognitiveModel: UserCognitiveModel) {
        self.progress = progress
        self.cognitiveModel = cognitiveModel
    }

    /// Resets eligibility state (called after a full progress reset).
    public func reset() {
        isEligibleForTransition = false
        transitionConfidence    = 0
    }

    // MARK: - Public API

    /// Evaluates whether the user should advance.
    /// - Returns: The next phase if eligible, `nil` otherwise.
    @discardableResult
    public func evaluateTransition() -> LearningPhase? {
        guard let nextPhase = progress.currentPhase.next else {
            isEligibleForTransition = false
            transitionConfidence    = 0
            return nil
        }

        let phaseResults = progress.recentResults(
            count: Self.minPuzzlesForAdvancement,
            for: progress.currentPhase
        )

        guard phaseResults.count >= Self.minPuzzlesForAdvancement else {
            isEligibleForTransition = false
            transitionConfidence    = 0
            return nil
        }

        let stabilityResults = Array(phaseResults.suffix(Self.stabilityWindow))
        let window = PerformanceWindow.compute(from: stabilityResults, weightedRecent: true)

        let eligible = cognitiveModel.isEligibleForProgression(window: window)
        isEligibleForTransition = eligible
        transitionConfidence    = (window.successRate / cognitiveModel.progressionThreshold)
            .clamped(to: 0...1)

        return eligible ? nextPhase : nil
    }

    /// Commits the transition to the given phase.
    /// - Returns: `true` if the transition was valid and applied.
    @discardableResult
    public func confirmTransition(to phase: LearningPhase) -> Bool {
        guard phase == progress.currentPhase.next else { return false }
        progress.advanceToPhase(phase)
        isEligibleForTransition = false
        transitionConfidence    = 0
        return true
    }
}
