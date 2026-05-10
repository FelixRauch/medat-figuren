import Foundation

/// Processes puzzle results and updates the `UserCognitiveModel` (Layer 3).
///
/// This engine is stateless — it reads signals from results and tells the model
/// how to adapt. Separation from the model keeps adaptation logic testable.
public final class CognitiveModelEngine {

    public init() {}

    /// Process one result: update the model and return the computed performance window.
    @discardableResult
    public func process(
        result: PuzzleResult,
        model: UserCognitiveModel,
        allResults: [PuzzleResult]
    ) -> PerformanceWindow {
        // Use last 20 results, weighted by recency
        let recent = Array(allResults.suffix(20))
        let window = PerformanceWindow.compute(from: recent, weightedRecent: true)
        model.update(with: result, window: window)
        return window
    }

    /// Composite engagement score incorporating multiple behavioral signals.
    ///
    /// - Parameter window: Recent performance window.
    /// - Parameter hesitationTime: Seconds the user waited before starting the task.
    /// - Parameter sessionLengthDelta: Change in session length vs. previous session (positive = longer).
    /// - Returns: Engagement score in [0, 1].
    public func engagementScore(
        window: PerformanceWindow,
        hesitationTime: TimeInterval,
        sessionLengthDelta: TimeInterval
    ) -> Double {
        // Success rate contributes 50 %
        var score = window.successRate * 0.50
        // Long hesitation before starting indicates low engagement (up to -20 %)
        score -= Swift.min(hesitationTime / 30.0, 0.20) * 0.25
        // Longer session vs. last indicates engagement (up to +25 %)
        score += Swift.min(Swift.max(sessionLengthDelta, 0) / 300.0, 0.25) * 0.25
        return score.clamped(to: 0...1)
    }
}
