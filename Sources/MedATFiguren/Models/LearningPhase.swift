import Foundation

/// The five cognitive training phases.
///
/// Users always progress **forward** — no backward looping.
/// Each phase changes the *cognitive strategy* required, not just difficulty.
public enum LearningPhase: Int, CaseIterable, Codable, Sendable, Equatable, Hashable {
    case perceptualOnboarding    = 1
    case structuredDecomposition = 2
    case mentalPrediction        = 3
    case examSimulation          = 4
    case mastery                 = 5
}

// MARK: - Display

extension LearningPhase {
    public var displayName: String {
        switch self {
        case .perceptualOnboarding:    return "Phase 1 – Perceptual Onboarding"
        case .structuredDecomposition: return "Phase 2 – Structured Decomposition"
        case .mentalPrediction:        return "Phase 3 – Mental Prediction"
        case .examSimulation:          return "Phase 4 – Exam Simulation"
        case .mastery:                 return "Phase 5 – Mastery"
        }
    }

    public var shortName: String {
        switch self {
        case .perceptualOnboarding:    return "Onboarding"
        case .structuredDecomposition: return "Decomposition"
        case .mentalPrediction:        return "Prediction"
        case .examSimulation:          return "Exam"
        case .mastery:                 return "Mastery"
        }
    }

    public var phaseDescription: String {
        switch self {
        case .perceptualOnboarding:
            return "Learn how fragments form a complete shape through direct manipulation."
        case .structuredDecomposition:
            return "Recognize structural relationships with reduced visual guidance."
        case .mentalPrediction:
            return "Predict piece orientations and placements before verifying."
        case .examSimulation:
            return "Solve puzzles under exam-like time pressure without assistance."
        case .mastery:
            return "Achieve near-automatic visuospatial performance at maximum difficulty."
        }
    }

    public var cognitiveMode: String {
        switch self {
        case .perceptualOnboarding:    return "External visual understanding"
        case .structuredDecomposition: return "Guided structural reasoning"
        case .mentalPrediction:        return "Mental rotation + pre-action prediction"
        case .examSimulation:          return "Fully internal problem solving under time pressure"
        case .mastery:                 return "Fast, near-automatic visuospatial processing"
        }
    }
}

// MARK: - Progression

extension LearningPhase {
    /// Returns the next phase, or `nil` if already at mastery.
    public var next: LearningPhase? {
        LearningPhase(rawValue: rawValue + 1)
    }

    /// Returns the previous phase, or `nil` if at the first phase.
    public var previous: LearningPhase? {
        LearningPhase(rawValue: rawValue - 1)
    }
}

// MARK: - Difficulty Envelope

extension LearningPhase {
    /// Allowed difficulty range for this phase.
    public var difficultyEnvelope: DifficultyEnvelope {
        switch self {
        case .perceptualOnboarding:
            return DifficultyEnvelope(axisBRange: (0.0, 0.20), pieceCountRange: (1, 2))
        case .structuredDecomposition:
            return DifficultyEnvelope(axisBRange: (0.1, 0.45), pieceCountRange: (2, 4))
        case .mentalPrediction:
            return DifficultyEnvelope(axisBRange: (0.35, 0.65), pieceCountRange: (3, 5))
        case .examSimulation:
            return DifficultyEnvelope(axisBRange: (0.50, 0.80), pieceCountRange: (5, 6))
        case .mastery:
            return DifficultyEnvelope(axisBRange: (0.70, 1.00), pieceCountRange: (5, 6))
        }
    }

    /// Starting difficulty when entering this phase.
    public var startingDifficulty: DifficultyLevel {
        let env = difficultyEnvelope
        return DifficultyLevel(
            pieceCount: env.pieceCountRange.min,
            ambiguity: env.axisBRange.min + 0.05
        ).clamped(to: env)
    }
}

// MARK: - Interaction Rules

extension LearningPhase {
    public var interactionMode: InteractionMode {
        switch self {
        case .perceptualOnboarding:    return .fullAssistance
        case .structuredDecomposition: return .guidedStructure
        case .mentalPrediction:        return .mentalPrediction
        case .examSimulation:          return .examConditions
        case .mastery:                 return .mastery
        }
    }

    public var showsEdgeHighlighting: Bool { self == .perceptualOnboarding }
    public var snappingEnabled: Bool {
        self == .perceptualOnboarding || self == .structuredDecomposition
    }
    public var snappingTolerance: Double {
        switch self {
        case .perceptualOnboarding:    return 30
        case .structuredDecomposition: return 15
        default:                       return 0
        }
    }
    public var requiresPredictionStep: Bool { self == .mentalPrediction }
    public var isMultipleChoiceFormat: Bool {
        self == .examSimulation || self == .mastery
    }
    public var hasTimeLimit: Bool { self == .examSimulation || self == .mastery }
    public var timeLimitSeconds: TimeInterval {
        switch self {
        case .examSimulation: return 45
        case .mastery:        return 25
        default:              return 0
        }
    }
    public var hintsAllowed: Bool {
        self == .perceptualOnboarding || self == .structuredDecomposition
    }
}

// MARK: - Interaction Mode

/// The interaction mode governs what cognitive operation the UI asks from the user.
public enum InteractionMode: String, Codable, Sendable {
    /// Phase 1: drag & drop, snapping, edge highlighting, immediate feedback.
    case fullAssistance
    /// Phase 2: drag & drop, reduced snapping, no edge highlighting.
    case guidedStructure
    /// Phase 3: must predict orientation/placement first, then verify by assembling.
    case mentalPrediction
    /// Phase 4: timed multiple-choice, no hints.
    case examConditions
    /// Phase 5: accelerated timed multiple-choice, extreme ambiguity.
    case mastery
}
