import Foundation
import Observation

/// Central application environment — injected via `@Environment` throughout the view hierarchy.
///
/// Owns all service instances and acts as the single coordination point for
/// recording results, triggering adaptive updates, and persisting state.
@Observable
public final class AppEnvironment {

    // MARK: - Domain objects

    public let progress: UserProgress
    public let cognitiveModel: UserCognitiveModel

    // MARK: - Services

    public let difficultyEngine: AdaptiveDifficultyEngine
    public let progressionManager: PhaseProgressionManager
    public let puzzleGenerator: PuzzleGenerator
    private let cognitiveModelEngine: CognitiveModelEngine
    private let persistence: PersistenceManager

    // MARK: - Init

    public init(persistence: PersistenceManager = .shared) {
        self.persistence = persistence

        let loadedProgress = (try? persistence.loadProgress()) ?? UserProgress()
        let loadedModel    = (try? persistence.loadCognitiveModel()) ?? UserCognitiveModel()

        self.progress           = loadedProgress
        self.cognitiveModel     = loadedModel
        self.difficultyEngine   = AdaptiveDifficultyEngine(phase: loadedProgress.currentPhase)
        self.progressionManager = PhaseProgressionManager(
            progress: loadedProgress,
            cognitiveModel: loadedModel
        )
        self.puzzleGenerator      = PuzzleGenerator()
        self.cognitiveModelEngine = CognitiveModelEngine()
    }

    // MARK: - Session lifecycle

    public func beginSession() {
        progress.startSession()
    }

    // MARK: - Result recording

    /// Records a result, updates all adaptive layers, and persists state.
    public func record(result: PuzzleResult) {
        progress.recordResult(result)

        // Layer 3: update personal cognitive model
        cognitiveModelEngine.process(
            result: result,
            model: cognitiveModel,
            allResults: progress.results
        )

        // Layer 2: adjust within-phase difficulty
        let recent = progress.recentResults(count: 20, for: progress.currentPhase)
        difficultyEngine.adjust(recentResults: recent, cognitiveModel: cognitiveModel)

        // Layer 1: evaluate phase transition eligibility
        progressionManager.evaluateTransition()

        save()
    }

    // MARK: - Phase transition

    /// Confirms advancement after showing the transition screen.
    public func confirmPhaseTransition() {
        guard let next = progress.currentPhase.next,
              progressionManager.isEligibleForTransition else { return }
        if progressionManager.confirmTransition(to: next) {
            difficultyEngine.resetForPhase(next)
            save()
        }
    }

    // MARK: - Reset

    /// Wipes all saved progress and cognitive model data back to factory defaults.
    public func resetProgress() {
        persistence.resetAllProgress()
        progress.reset()
        cognitiveModel.reset()
        difficultyEngine.resetForPhase(.phase1)
        progressionManager.reset()
    }

    // MARK: - Puzzle generation

    public func nextPuzzle() -> Puzzle {
        puzzleGenerator.generate(
            for: progress.currentPhase,
            difficulty: difficultyEngine.currentDifficulty
        )
    }

    // MARK: - Private

    private func save() {
        try? persistence.saveProgress(progress)
        try? persistence.saveCognitiveModel(cognitiveModel)
    }
}
