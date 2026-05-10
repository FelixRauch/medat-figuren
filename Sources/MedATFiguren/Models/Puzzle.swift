import Foundation

// MARK: - PuzzleShape

/// A polygon shape defined in normalized [0, 1] × [0, 1] coordinates.
/// Carries a library of decompositions keyed by piece count.
public struct PuzzleShape: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    /// The outline polygon (normalized vertices).
    public let outline: [NormalizedPoint]
    /// All available decompositions. Key = number of pieces.
    public let decompositions: [Int: [ShapePiece]]

    public init(
        id: String,
        name: String,
        outline: [NormalizedPoint],
        decompositions: [Int: [ShapePiece]]
    ) {
        self.id = id
        self.name = name
        self.outline = outline
        self.decompositions = decompositions
    }

    public var availablePieceCounts: [Int] {
        decompositions.keys.sorted()
    }

    // MARK: Codable (manual — [Int: [ShapePiece]] keys must be strings in JSON)

    enum CodingKeys: String, CodingKey {
        case id, name, outline, decompositionKeys, decompositionValues
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(outline, forKey: .outline)
        let sorted = decompositions.sorted { $0.key < $1.key }
        try c.encode(sorted.map(\.key), forKey: .decompositionKeys)
        try c.encode(sorted.map(\.value), forKey: .decompositionValues)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        outline = try c.decode([NormalizedPoint].self, forKey: .outline)
        let keys = try c.decode([Int].self, forKey: .decompositionKeys)
        let values = try c.decode([[ShapePiece]].self, forKey: .decompositionValues)
        decompositions = Dictionary(uniqueKeysWithValues: zip(keys, values))
    }
}

// MARK: - ShapePiece

/// One piece in a puzzle decomposition.
public struct ShapePiece: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    /// Polygon vertices in normalized coordinates.
    public let vertices: [NormalizedPoint]
    /// Rotation applied to this piece in the correct solution (radians).
    public let solutionRotation: Double
    /// Distractor rotation angles offered as wrong choices.
    public let distractorRotations: [Double]

    public init(
        id: String,
        vertices: [NormalizedPoint],
        solutionRotation: Double = 0,
        distractorRotations: [Double] = [.pi / 2, .pi, 3 * .pi / 2]
    ) {
        self.id = id
        self.vertices = vertices
        self.solutionRotation = solutionRotation
        self.distractorRotations = distractorRotations
    }
}

// MARK: - Puzzle

/// A single puzzle instance to be solved.
public struct Puzzle: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let shape: PuzzleShape
    public let difficulty: DifficultyLevel
    public let phase: LearningPhase
    public let activePieceCount: Int
    /// Set for Phase 4 & 5 (multiple-choice format).
    public let multipleChoiceOptions: [MultipleChoiceOption]?
    public let correctOptionIndex: Int?
    public let createdAt: Date

    public init(
        shape: PuzzleShape,
        difficulty: DifficultyLevel,
        phase: LearningPhase,
        activePieceCount: Int,
        multipleChoiceOptions: [MultipleChoiceOption]? = nil,
        correctOptionIndex: Int? = nil
    ) {
        self.id = UUID()
        self.shape = shape
        self.difficulty = difficulty
        self.phase = phase
        self.activePieceCount = activePieceCount
        self.multipleChoiceOptions = multipleChoiceOptions
        self.correctOptionIndex = correctOptionIndex
        self.createdAt = Date()
    }

    /// Pieces for direct assembly (Phases 1–3). `nil` when puzzle is multiple-choice only.
    public var assemblyPieces: [ShapePiece]? {
        shape.decompositions[activePieceCount]
    }
}

// MARK: - MultipleChoiceOption

/// One answer option in the multiple-choice format (Phases 4–5).
public struct MultipleChoiceOption: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let pieces: [ShapePiece]
    public let isCorrect: Bool

    public init(pieces: [ShapePiece], isCorrect: Bool) {
        self.id = UUID()
        self.pieces = pieces
        self.isCorrect = isCorrect
    }
}
