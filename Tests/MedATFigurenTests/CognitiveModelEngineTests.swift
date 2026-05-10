import XCTest
@testable import MedATFiguren

final class CognitiveModelEngineTests: XCTestCase {

    private func makeModel() -> UserCognitiveModel { UserCognitiveModel() }

    private func makeResult(correct: Bool, phase: LearningPhase = .perceptualOnboarding) -> PuzzleResult {
        PuzzleResult(
            puzzleID: UUID(),
            phase: phase,
            difficulty: DifficultyLevel(pieceCount: 1, ambiguity: 0.1),
            isCorrect: correct,
            solveTime: 12
        )
    }

    // MARK: - Initial state

    func testModelStartsUncalibrated() {
        let model = makeModel()
        XCTAssertFalse(model.isCalibrated)
        XCTAssertEqual(model.puzzlesAttemptedForCalibration, 0)
    }

    func testDefaultThresholds() {
        let model = makeModel()
        XCTAssertEqual(model.engagementFloor, 0.60, accuracy: 0.001)
        XCTAssertEqual(model.progressionThreshold, 0.78, accuracy: 0.001)
    }

    // MARK: - Calibration

    func testCalibratesAfterRequiredPuzzleCount() {
        let engine = CognitiveModelEngine()
        let model = makeModel()
        var results: [PuzzleResult] = []

        for i in 0..<UserCognitiveModel.calibrationPuzzleCount {
            let result = makeResult(correct: i % 5 != 0)  // ~80 % success
            results.append(result)
            engine.process(result: result, model: model, allResults: results)
        }

        XCTAssertTrue(model.isCalibrated)
    }

    func testDoesNotCalibrateBeforeRequiredCount() {
        let engine = CognitiveModelEngine()
        let model = makeModel()
        var results: [PuzzleResult] = []

        for i in 0..<(UserCognitiveModel.calibrationPuzzleCount - 1) {
            let result = makeResult(correct: i % 2 == 0)
            results.append(result)
            engine.process(result: result, model: model, allResults: results)
        }

        XCTAssertFalse(model.isCalibrated)
    }

    // MARK: - Asymmetry principle

    /// The asymmetry principle states E-floor adapts at rate 0.08 and P-threshold at 0.02.
    /// We verify this by performing a single update and comparing the magnitudes of change.
    func testEngagementFloorAdaptsFasterThanProgressionThreshold() {
        let model = makeModel()

        // Calibrate the model with 80 % success rate
        var results: [PuzzleResult] = []
        for i in 0..<UserCognitiveModel.calibrationPuzzleCount {
            let result = makeResult(correct: i % 5 != 0)
            results.append(result)
            let w = PerformanceWindow.compute(from: results)
            model.update(with: result, window: w)
        }
        XCTAssertTrue(model.isCalibrated)

        let eFloorBefore     = model.engagementFloor
        let pThresholdBefore = model.progressionThreshold

        // Single update with a 100 % window of 20 results
        let perfectWindow = PerformanceWindow(
            successRate: 1.0, averageSolveTime: 10, hintUsageRate: 0, sampleCount: 20)
        let dummyResult = makeResult(correct: true)
        model.update(with: dummyResult, window: perfectWindow)

        let eFloorDelta     = abs(model.engagementFloor - eFloorBefore)
        let pThresholdDelta = abs(model.progressionThreshold - pThresholdBefore)

        // E-floor rate (0.08) must produce a larger per-update delta than P-threshold rate (0.02)
        XCTAssertGreaterThan(
            eFloorDelta, pThresholdDelta,
            "E-floor (rate=0.08) should change more per update than P-threshold (rate=0.02)"
        )
    }

    // MARK: - Engagement floor threat detection

    func testEngagementFloorThreatDetected() {
        let model = makeModel()
        // Default E-floor is 0.60
        XCTAssertTrue(model.isEngagementThreatened(successRate: 0.50))
        XCTAssertFalse(model.isEngagementThreatened(successRate: 0.75))
        XCTAssertFalse(model.isEngagementThreatened(successRate: 0.60))  // at boundary = not threatened
    }

    // MARK: - Progression threshold

    func testProgressionEligibilityRequiresMinimumSamples() {
        let model = makeModel()
        // Window with only 5 samples — not enough regardless of success rate
        let window = PerformanceWindow(
            successRate: 0.95, averageSolveTime: 10, hintUsageRate: 0, sampleCount: 5)
        XCTAssertFalse(model.isEligibleForProgression(window: window))
    }

    func testProgressionEligibilityWithSufficientPerformance() {
        let model = makeModel()
        // Default P-threshold is 0.78; window with 85 % over 15 samples → eligible
        let window = PerformanceWindow(
            successRate: 0.85, averageSolveTime: 10, hintUsageRate: 0, sampleCount: 15)
        XCTAssertTrue(model.isEligibleForProgression(window: window))
    }

    func testProgressionNotEligibleBelowThreshold() {
        let model = makeModel()
        let window = PerformanceWindow(
            successRate: 0.65, averageSolveTime: 10, hintUsageRate: 0, sampleCount: 15)
        XCTAssertFalse(model.isEligibleForProgression(window: window))
    }

    // MARK: - Thresholds stay within bounds

    func testThresholdsRemainsWithinBounds() {
        let engine = CognitiveModelEngine()
        let model = makeModel()
        var results: [PuzzleResult] = []

        // Run 100 all-correct results
        for _ in 0..<100 {
            let result = makeResult(correct: true)
            results.append(result)
            engine.process(result: result, model: model, allResults: results)
        }
        XCTAssertLessThanOrEqual(model.engagementFloor, 0.82)
        XCTAssertLessThanOrEqual(model.progressionThreshold, 0.92)

        // Run 100 all-wrong results
        for _ in 0..<100 {
            let result = makeResult(correct: false)
            results.append(result)
            engine.process(result: result, model: model, allResults: results)
        }
        XCTAssertGreaterThanOrEqual(model.engagementFloor, 0.45)
        XCTAssertGreaterThanOrEqual(model.progressionThreshold, 0.65)
    }
}
