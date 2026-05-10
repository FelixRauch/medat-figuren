import XCTest
@testable import MedATFiguren

final class PhaseProgressionManagerTests: XCTestCase {

    // MARK: - Helpers

    private func makeProgress() -> UserProgress { UserProgress() }
    private func makeCalibratedModel(successRate: Double) -> UserCognitiveModel {
        // Return a model whose P-threshold is slightly below successRate
        // to simulate a calibrated state.
        let model = UserCognitiveModel()
        // Drive calibration with the target success rate
        var results: [PuzzleResult] = []
        for i in 0..<UserCognitiveModel.calibrationPuzzleCount {
            let correct = Double(i) / Double(UserCognitiveModel.calibrationPuzzleCount) < successRate
            let result = PuzzleResult(
                puzzleID: UUID(), phase: .perceptualOnboarding,
                difficulty: DifficultyLevel(pieceCount: 1, ambiguity: 0.1),
                isCorrect: correct, solveTime: 10)
            results.append(result)
            let window = PerformanceWindow.compute(from: results)
            model.update(with: result, window: window)
        }
        return model
    }

    private func addResults(
        to progress: UserProgress,
        count: Int,
        correct: Int,
        phase: LearningPhase
    ) {
        for i in 0..<count {
            let result = PuzzleResult(
                puzzleID: UUID(), phase: phase,
                difficulty: DifficultyLevel(pieceCount: 2, ambiguity: 0.2),
                isCorrect: i < correct, solveTime: 15)
            progress.recordResult(result)
        }
    }

    // MARK: - No transition before minimum puzzles

    func testNoTransitionBeforeMinimumPuzzles() {
        let progress = makeProgress()
        let model = makeCalibratedModel(successRate: 0.90)
        let manager = PhaseProgressionManager(progress: progress, cognitiveModel: model)

        // Only 5 results — below the minimum of 15
        addResults(to: progress, count: 5, correct: 5, phase: .perceptualOnboarding)

        let result = manager.evaluateTransition()
        XCTAssertNil(result)
        XCTAssertFalse(manager.isEligibleForTransition)
    }

    // MARK: - Transition granted with sufficient performance

    func testTransitionGrantedWithHighSuccessRate() {
        let progress = makeProgress()
        let model = makeCalibratedModel(successRate: 0.85)
        let manager = PhaseProgressionManager(progress: progress, cognitiveModel: model)

        // 15 results, all correct
        addResults(to: progress, count: 15, correct: 15, phase: .perceptualOnboarding)

        let next = manager.evaluateTransition()
        XCTAssertEqual(next, .structuredDecomposition)
        XCTAssertTrue(manager.isEligibleForTransition)
    }

    // MARK: - Transition denied with low success rate

    func testTransitionDeniedWithLowSuccessRate() {
        let progress = makeProgress()
        let model = makeCalibratedModel(successRate: 0.80)
        let manager = PhaseProgressionManager(progress: progress, cognitiveModel: model)

        // 15 results, only 6 correct (40 %)
        addResults(to: progress, count: 15, correct: 6, phase: .perceptualOnboarding)

        let next = manager.evaluateTransition()
        XCTAssertNil(next)
        XCTAssertFalse(manager.isEligibleForTransition)
    }

    // MARK: - Confirm transition advances phase

    func testConfirmTransitionAdvancesPhase() {
        let progress = makeProgress()
        let model = makeCalibratedModel(successRate: 0.90)
        let manager = PhaseProgressionManager(progress: progress, cognitiveModel: model)

        addResults(to: progress, count: 15, correct: 15, phase: .perceptualOnboarding)
        manager.evaluateTransition()
        let confirmed = manager.confirmTransition(to: .structuredDecomposition)

        XCTAssertTrue(confirmed)
        XCTAssertEqual(progress.currentPhase, .structuredDecomposition)
    }

    // MARK: - No backward transition

    func testCannotTransitionBackward() {
        let progress = makeProgress()
        let model = makeCalibratedModel(successRate: 0.90)
        let manager = PhaseProgressionManager(progress: progress, cognitiveModel: model)

        // Advance to phase 2 first
        addResults(to: progress, count: 15, correct: 15, phase: .perceptualOnboarding)
        manager.evaluateTransition()
        manager.confirmTransition(to: .structuredDecomposition)

        // Try to go back to phase 1
        let result = manager.confirmTransition(to: .perceptualOnboarding)
        XCTAssertFalse(result)
        XCTAssertEqual(progress.currentPhase, .structuredDecomposition)
    }

    // MARK: - No transition at mastery (end of progression)

    func testNoTransitionAtMastery() {
        let progress = makeProgress()
        // Manually advance to mastery
        for phase in [LearningPhase.structuredDecomposition, .mentalPrediction, .examSimulation, .mastery] {
            progress.advanceToPhase(phase)
        }

        let model = makeCalibratedModel(successRate: 0.95)
        let manager = PhaseProgressionManager(progress: progress, cognitiveModel: model)
        addResults(to: progress, count: 20, correct: 20, phase: .mastery)

        let result = manager.evaluateTransition()
        XCTAssertNil(result, "No transition beyond mastery phase")
    }

    // MARK: - Transition confidence

    func testTransitionConfidenceIsProportional() {
        let progress = makeProgress()
        let model = makeCalibratedModel(successRate: 0.90)
        let manager = PhaseProgressionManager(progress: progress, cognitiveModel: model)

        addResults(to: progress, count: 15, correct: 15, phase: .perceptualOnboarding)
        manager.evaluateTransition()

        XCTAssertGreaterThan(manager.transitionConfidence, 0)
        XCTAssertLessThanOrEqual(manager.transitionConfidence, 1)
    }
}
