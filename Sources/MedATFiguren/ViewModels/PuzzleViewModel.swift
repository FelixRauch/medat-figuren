import Foundation
import Observation

/// ViewModel for the active puzzle-solving session.
///
/// Drives the three interaction modes:
/// * Assembly (Phases 1–2): tracks piece placement.
/// * Prediction (Phase 3): tracks prediction accuracy then assembly.
/// * Multiple choice (Phases 4–5): tracks selected option.
@Observable
public final class PuzzleViewModel {

    // MARK: - State machine

    public enum SessionState: Equatable {
        case loading
        case predicting                       // Phase 3 — mental prediction step
        case assembling                       // Phases 1–2 — drag & drop
        case multipleChoice                   // Phases 4–5 — select an option
        case showingFeedback(isCorrect: Bool)
        case phaseTransitionAvailable
        case finished
    }

    public private(set) var state: SessionState = .loading
    public private(set) var currentPuzzle: Puzzle?
    public private(set) var elapsedTime: TimeInterval = 0
    public private(set) var selectedOptionIndex: Int?

    // Phase 3 prediction tracking
    public private(set) var predictedRotations: [String: Double] = [:]  // pieceID → rotation
    public private(set) var predictionSubmitted: Bool = false

    // Placement tracking for Phases 1–2
    /// Piece IDs that have been placed correctly on the canvas.
    public private(set) var correctlyPlacedIDs: Set<String> = []

    // MARK: - Dependencies

    private let env: AppEnvironment
    private var puzzleStartTime: Date?
    private var hintUsed: Bool = false

    // MARK: - Init

    public init(env: AppEnvironment) {
        self.env = env
    }

    // MARK: - Lifecycle

    public func startSession() {
        env.beginSession()
        loadNextPuzzle()
    }

    public func loadNextPuzzle() {
        let puzzle = env.nextPuzzle()
        currentPuzzle    = puzzle
        elapsedTime      = 0
        selectedOptionIndex = nil
        predictedRotations  = [:]
        predictionSubmitted = false
        correctlyPlacedIDs  = []
        hintUsed            = false
        puzzleStartTime     = Date()
        state = initialState(for: puzzle.phase)
    }

    // MARK: - Phase 3 — Prediction step

    public func setPredictedRotation(_ radians: Double, forPieceID id: String) {
        predictedRotations[id] = radians
    }

    public func submitPrediction() {
        guard state == .predicting else { return }
        predictionSubmitted = true
        state = .assembling  // allow verification
    }

    // MARK: - Phase 1 & 2 — Assembly

    /// Call when a piece has been placed in the correct position.
    public func piecePlacedCorrectly(id: String) {
        correctlyPlacedIDs.insert(id)
        checkAssemblyComplete()
    }

    /// Call when the user submits an assembly that doesn't meet the correctness criteria.
    public func submitIncorrectAssembly() {
        commit(isCorrect: false, predictionCorrect: nil)
    }

    // MARK: - Phase 4 & 5 — Multiple choice

    public func selectOption(index: Int) {
        guard state == .multipleChoice, let puzzle = currentPuzzle else { return }
        selectedOptionIndex = index
        let correct = index == puzzle.correctOptionIndex
        commit(isCorrect: correct, predictionCorrect: nil)
    }

    // MARK: - Hints

    public func useHint() {
        hintUsed = true
    }

    // MARK: - Transition confirmation

    public func confirmPhaseTransition() {
        env.confirmPhaseTransition()
        state = .loading
        loadNextPuzzle()
    }

    // MARK: - Private helpers

    private func initialState(for phase: LearningPhase) -> SessionState {
        switch phase.interactionMode {
        case .mentalPrediction: return .predicting
        case .examConditions, .mastery: return .multipleChoice
        default: return .assembling
        }
    }

    private func checkAssemblyComplete() {
        guard let puzzle = currentPuzzle,
              let pieces = puzzle.assemblyPieces else { return }
        if correctlyPlacedIDs.count >= pieces.count {
            let correct = true  // All pieces placed → correct by definition
            let predCorrect: Bool? = predictionSubmitted ? evaluatePrediction() : nil
            commit(isCorrect: correct, predictionCorrect: predCorrect)
        }
    }

    private func evaluatePrediction() -> Bool {
        guard let puzzle = currentPuzzle, let pieces = puzzle.assemblyPieces else { return false }
        // A prediction is correct when each predicted rotation is within 10° of the solution
        return pieces.allSatisfy { piece in
            guard let predicted = predictedRotations[piece.id] else { return false }
            let diff = abs(predicted - piece.solutionRotation)
                .truncatingRemainder(dividingBy: .pi * 2)
            return diff < (.pi / 18)  // 10°
        }
    }

    private func commit(isCorrect: Bool, predictionCorrect: Bool?) {
        guard let puzzle = currentPuzzle else { return }

        let solveTime = puzzleStartTime.map { Date().timeIntervalSince($0) } ?? 0
        elapsedTime = solveTime

        let result = PuzzleResult(
            puzzleID: puzzle.id,
            phase: puzzle.phase,
            difficulty: puzzle.difficulty,
            isCorrect: isCorrect,
            solveTime: solveTime,
            hintUsed: hintUsed,
            predictionCorrect: predictionCorrect
        )

        env.record(result: result)
        state = .showingFeedback(isCorrect: isCorrect)

        // Check if eligible for phase transition
        if env.progressionManager.isEligibleForTransition {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.state = .phaseTransitionAvailable
            }
        }
    }
}
