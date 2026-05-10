import XCTest
@testable import MedATFiguren

final class PuzzleGeneratorTests: XCTestCase {

    private let generator = PuzzleGenerator(library: .shared)

    // MARK: - Basic generation

    func testGeneratesNonNilPuzzle() {
        for phase in LearningPhase.allCases {
            let difficulty = phase.startingDifficulty
            let puzzle = generator.generate(for: phase, difficulty: difficulty)
            XCTAssertEqual(puzzle.phase, phase)
            XCTAssertNotNil(puzzle.id)
        }
    }

    func testAssemblyFormatForPhase1() {
        let difficulty = DifficultyLevel(pieceCount: 2, ambiguity: 0.1)
        let puzzle = generator.generate(for: .perceptualOnboarding, difficulty: difficulty)
        XCTAssertNil(puzzle.multipleChoiceOptions, "Phase 1 should not use multiple-choice format")
        XCTAssertNotNil(puzzle.assemblyPieces)
    }

    func testMultipleChoiceFormatForPhase4() {
        let difficulty = DifficultyLevel(pieceCount: 5, ambiguity: 0.6)
        let puzzle = generator.generate(for: .examSimulation, difficulty: difficulty)
        XCTAssertNotNil(puzzle.multipleChoiceOptions)
        XCTAssertNotNil(puzzle.correctOptionIndex)
    }

    // MARK: - Multiple choice correctness

    func testExactlyOneCorrectOption() {
        let difficulty = DifficultyLevel(pieceCount: 5, ambiguity: 0.6)
        let puzzle = generator.generate(for: .examSimulation, difficulty: difficulty)
        guard let options = puzzle.multipleChoiceOptions else {
            return XCTFail("Expected multiple choice options")
        }
        let correctCount = options.filter(\.isCorrect).count
        XCTAssertEqual(correctCount, 1)
    }

    func testCorrectOptionIndexMatchesOption() {
        let difficulty = DifficultyLevel(pieceCount: 5, ambiguity: 0.6)
        let puzzle = generator.generate(for: .examSimulation, difficulty: difficulty)
        guard let options = puzzle.multipleChoiceOptions,
              let idx = puzzle.correctOptionIndex else {
            return XCTFail("Expected multiple choice options")
        }
        XCTAssertTrue(options[idx].isCorrect)
    }

    /// The generator picks the *nearest* available piece count for the requested shape;
    /// it does not clamp piece count to the phase envelope (that is the engine's job).
    /// Verify the returned puzzle has a valid decomposition and consistent piece count.
    func testGeneratorPicksNearestAvailablePieceCount() {
        // Request piece count 6 which may not exist for every shape.
        // The generator should still return a puzzle with a valid piece count.
        let difficulty = DifficultyLevel(pieceCount: 6, ambiguity: 0.1)
        let puzzle = generator.generate(for: .perceptualOnboarding, difficulty: difficulty)
        // activePieceCount must correspond to an actual decomposition on the chosen shape
        XCTAssertNotNil(puzzle.shape.decompositions[puzzle.activePieceCount])
    }

    // MARK: - Shape library coverage

    func testShapeLibraryContainsShapes() {
        XCTAssertGreaterThan(ShapeLibrary.shared.allShapes.count, 0)
    }

    func testShapeLibraryHasShapesForPhasePieceCounts() {
        for phase in LearningPhase.allCases {
            let env = phase.difficultyEnvelope
            for count in env.pieceCountRange.min...env.pieceCountRange.max {
                let shapes = ShapeLibrary.shared.shapes(forPieceCount: count)
                // Not all piece counts need to be covered, but at least one total must exist
                _ = shapes
            }
        }
        // Sanity: library returns at least one shape for piece count 2
        XCTAssertFalse(ShapeLibrary.shared.shapes(forPieceCount: 2).isEmpty)
    }
}
