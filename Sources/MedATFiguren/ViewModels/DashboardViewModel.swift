import Foundation
import Observation

/// ViewModel for the progress dashboard.
@Observable
public final class DashboardViewModel {

    // MARK: - Computed display data

    public var currentPhase: LearningPhase { env.progress.currentPhase }
    public var totalAttempted: Int         { env.progress.totalPuzzlesAttempted }
    public var overallAccuracy: Double     { env.progress.overallAccuracy }
    public var totalSessions: Int          { env.progress.totalSessionCount }
    public var engagementFloor: Double     { env.cognitiveModel.engagementFloor }
    public var progressionThreshold: Double { env.cognitiveModel.progressionThreshold }
    public var isCalibrated: Bool          { env.cognitiveModel.isCalibrated }

    /// Recent 20 results for charting.
    public var recentResults: [PuzzleResult] {
        env.progress.recentResults(count: 20)
    }

    /// Per-phase attempt and accuracy breakdown.
    public var phaseBreakdown: [PhaseStats] {
        LearningPhase.allCases.map { phase in
            let results = env.progress.results.filter { $0.phase == phase }
            let correct = results.filter(\.isCorrect).count
            return PhaseStats(
                phase: phase,
                attempted: results.count,
                accuracy: results.isEmpty ? 0 : Double(correct) / Double(results.count),
                isCurrentPhase: phase == env.progress.currentPhase
            )
        }
    }

    // MARK: - Dependencies

    private let env: AppEnvironment

    // MARK: - Init

    public init(env: AppEnvironment) {
        self.env = env
    }
}

// MARK: - Supporting types

public struct PhaseStats: Identifiable {
    public let phase: LearningPhase
    public let attempted: Int
    public let accuracy: Double
    public let isCurrentPhase: Bool

    public var id: Int { phase.rawValue }
}
