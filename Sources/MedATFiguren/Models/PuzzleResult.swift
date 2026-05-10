import Foundation

// MARK: - PuzzleResult

/// The outcome of a single puzzle attempt.
public struct PuzzleResult: Codable, Sendable, Identifiable {
    public let id: UUID
    public let puzzleID: UUID
    public let phase: LearningPhase
    public let difficulty: DifficultyLevel
    public let isCorrect: Bool
    /// Wall-clock time from puzzle display to answer submission.
    public let solveTime: TimeInterval
    public let hintUsed: Bool
    /// Phase 3 only: whether the mental prediction step was accurate.
    public let predictionCorrect: Bool?
    public let timestamp: Date

    public init(
        puzzleID: UUID,
        phase: LearningPhase,
        difficulty: DifficultyLevel,
        isCorrect: Bool,
        solveTime: TimeInterval,
        hintUsed: Bool = false,
        predictionCorrect: Bool? = nil
    ) {
        self.id = UUID()
        self.puzzleID = puzzleID
        self.phase = phase
        self.difficulty = difficulty
        self.isCorrect = isCorrect
        self.solveTime = solveTime
        self.hintUsed = hintUsed
        self.predictionCorrect = predictionCorrect
        self.timestamp = Date()
    }
}

// MARK: - PerformanceWindow

/// Aggregate metrics over a window of puzzle results.
///
/// Recent results are weighted more heavily than older ones when
/// `weightedRecent` is enabled (matches the spec's "weighted recent > old" signal).
public struct PerformanceWindow: Sendable {
    public let successRate: Double
    public let averageSolveTime: TimeInterval
    public let hintUsageRate: Double
    public let sampleCount: Int

    public static let empty = PerformanceWindow(
        successRate: 0, averageSolveTime: 0, hintUsageRate: 0, sampleCount: 0)

    public static func compute(
        from results: [PuzzleResult],
        weightedRecent: Bool = true
    ) -> PerformanceWindow {
        guard !results.isEmpty else { return .empty }

        let n = Double(results.count)

        // Linear weights: index 0 = oldest (weight 1), last = newest (weight n)
        let weights: [Double]
        if weightedRecent && results.count > 1 {
            let total = (1.0 + n) * n / 2.0
            weights = (1...results.count).map { Double($0) / total }
        } else {
            weights = Array(repeating: 1.0 / n, count: results.count)
        }

        var weightedCorrect = 0.0
        var totalTime = 0.0
        var weightedHints = 0.0

        for (result, weight) in zip(results, weights) {
            weightedCorrect += result.isCorrect ? weight : 0
            totalTime += result.solveTime
            weightedHints += result.hintUsed ? weight : 0
        }

        return PerformanceWindow(
            successRate: weightedCorrect,
            averageSolveTime: totalTime / n,
            hintUsageRate: weightedHints,
            sampleCount: results.count
        )
    }
}
