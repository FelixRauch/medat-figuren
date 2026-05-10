import XCTest
@testable import MedATFiguren

final class AdaptiveDifficultyEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeEngine(phase: LearningPhase) -> AdaptiveDifficultyEngine {
        AdaptiveDifficultyEngine(phase: phase)
    }

    private func makeModel() -> UserCognitiveModel {
        UserCognitiveModel()
    }

    private func makeResults(count: Int, correct: Int, phase: LearningPhase) -> [PuzzleResult] {
        let difficulty = DifficultyLevel(pieceCount: 2, ambiguity: 0.1)
        return (0..<count).map { i in
            PuzzleResult(
                puzzleID: UUID(),
                phase: phase,
                difficulty: difficulty,
                isCorrect: i < correct,
                solveTime: 10
            )
        }
    }

    // MARK: - Initialization

    func testInitialDifficultyIsAtPhaseStart() {
        for phase in LearningPhase.allCases {
            let engine = makeEngine(phase: phase)
            let envelope = phase.difficultyEnvelope
            XCTAssertTrue(
                engine.currentDifficulty.isWithin(envelope),
                "Phase \(phase.rawValue) initial difficulty out of envelope"
            )
        }
    }

    // MARK: - No adjustment below sample size

    func testNoAdjustmentBelowMinimumSample() {
        let engine = makeEngine(phase: .perceptualOnboarding)
        let initial = engine.currentDifficulty
        let results = makeResults(count: 3, correct: 3, phase: .perceptualOnboarding)  // below min 5
        engine.adjust(recentResults: results, cognitiveModel: makeModel())
        XCTAssertEqual(engine.currentDifficulty, initial)
    }

    // MARK: - Success rate above target → increase difficulty

    func testHighSuccessRateIncreasesDifficulty() {
        let engine = makeEngine(phase: .structuredDecomposition)
        let initial = engine.currentDifficulty

        // 10/10 = 100 % success rate → well above targetHigh (0.85) even when weighted
        let results = makeResults(count: 10, correct: 10, phase: .structuredDecomposition)
        engine.adjust(recentResults: results, cognitiveModel: makeModel())

        XCTAssertGreaterThan(
            engine.currentDifficulty.normalizedScore,
            initial.normalizedScore,
            "Difficulty should increase after high success rate"
        )
    }

    // MARK: - Success rate below target → reduce difficulty

    func testLowSuccessRateReducesDifficulty() {
        let phase = LearningPhase.mentalPrediction
        let engine = makeEngine(phase: phase)

        // Manually push difficulty to mid-range first
        let results10 = makeResults(count: 10, correct: 9, phase: phase)
        engine.adjust(recentResults: results10, cognitiveModel: makeModel())
        let elevated = engine.currentDifficulty

        // Now simulate 50 % success rate → below targetLow (0.70)
        let results5 = makeResults(count: 10, correct: 5, phase: phase)
        engine.adjust(recentResults: results5, cognitiveModel: makeModel())

        XCTAssertLessThan(
            engine.currentDifficulty.normalizedScore,
            elevated.normalizedScore,
            "Difficulty should decrease after low success rate"
        )
    }

    // MARK: - Engagement floor triggers immediate reduction

    func testEngagementFloorTriggersReduction() {
        let engine = makeEngine(phase: .structuredDecomposition)
        // Push difficulty up
        let highResults = makeResults(count: 10, correct: 10, phase: .structuredDecomposition)
        engine.adjust(recentResults: highResults, cognitiveModel: makeModel())
        let elevated = engine.currentDifficulty

        // Use a model with a very high E-floor so 40 % triggers it
        let model = UserCognitiveModel()
        // Simulate calibration with artificially high floor by running 20 puzzles all correct
        let calibrationResults = makeResults(count: 20, correct: 20, phase: .perceptualOnboarding)
        for (i, result) in calibrationResults.enumerated() {
            let window = PerformanceWindow.compute(from: Array(calibrationResults.prefix(i + 1)))
            model.update(with: result, window: window)
        }

        // Now 40 % success: should be below the E-floor → reduce
        let lowResults = makeResults(count: 10, correct: 4, phase: .structuredDecomposition)
        engine.adjust(recentResults: lowResults, cognitiveModel: model)

        XCTAssertLessThan(
            engine.currentDifficulty.normalizedScore,
            elevated.normalizedScore,
            "Engagement floor breach should reduce difficulty"
        )
    }

    // MARK: - Difficulty stays within phase envelope

    func testDifficultyAlwaysStaysInPhaseEnvelope() {
        for phase in LearningPhase.allCases {
            let engine = makeEngine(phase: phase)
            let model = makeModel()
            // Repeatedly apply max and min success rates
            for _ in 0..<50 {
                let highResults = makeResults(count: 10, correct: 10, phase: phase)
                engine.adjust(recentResults: highResults, cognitiveModel: model)
                XCTAssertTrue(
                    engine.currentDifficulty.isWithin(phase.difficultyEnvelope),
                    "Difficulty exceeded envelope in phase \(phase.rawValue) after success"
                )

                let lowResults = makeResults(count: 10, correct: 1, phase: phase)
                engine.adjust(recentResults: lowResults, cognitiveModel: model)
                XCTAssertTrue(
                    engine.currentDifficulty.isWithin(phase.difficultyEnvelope),
                    "Difficulty exceeded envelope in phase \(phase.rawValue) after failure"
                )
            }
        }
    }

    // MARK: - Reset for new phase

    func testResetForPhaseInitializesCorrectly() {
        let engine = makeEngine(phase: .perceptualOnboarding)
        // Push up difficulty
        let highResults = makeResults(count: 10, correct: 10, phase: .perceptualOnboarding)
        engine.adjust(recentResults: highResults, cognitiveModel: makeModel())

        engine.resetForPhase(.structuredDecomposition)

        let newEnvelope = LearningPhase.structuredDecomposition.difficultyEnvelope
        XCTAssertTrue(engine.currentDifficulty.isWithin(newEnvelope))
    }
}
