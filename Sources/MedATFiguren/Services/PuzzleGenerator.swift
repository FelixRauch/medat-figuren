import Foundation

/// Generates `Puzzle` instances for a given phase and difficulty level.
///
/// For Phases 1–3 the puzzle uses the direct-assembly format.
/// For Phases 4–5 it uses the multiple-choice format with distractor options.
public final class PuzzleGenerator {

    private let library: ShapeLibrary

    public init(library: ShapeLibrary = .shared) {
        self.library = library
    }

    // MARK: - Public API

    public func generate(for phase: LearningPhase, difficulty: DifficultyLevel) -> Puzzle {
        let shape = library.randomShape(for: difficulty)
        let pieceCount = bestPieceCount(for: difficulty.pieceCount, availableIn: shape)

        if phase.isMultipleChoiceFormat {
            return multipleChoice(shape: shape, difficulty: difficulty, phase: phase, pieceCount: pieceCount)
        }
        return Puzzle(shape: shape, difficulty: difficulty, phase: phase, activePieceCount: pieceCount)
    }

    // MARK: - Private helpers

    private func bestPieceCount(for requested: Int, availableIn shape: PuzzleShape) -> Int {
        shape.availablePieceCounts
            .min { abs($0 - requested) < abs($1 - requested) }
            ?? requested
    }

    private func multipleChoice(
        shape: PuzzleShape,
        difficulty: DifficultyLevel,
        phase: LearningPhase,
        pieceCount: Int
    ) -> Puzzle {
        guard let correctPieces = shape.decompositions[pieceCount] else {
            // Fallback: assembly format if no decomposition exists
            return Puzzle(shape: shape, difficulty: difficulty, phase: phase, activePieceCount: pieceCount)
        }

        let correct = MultipleChoiceOption(pieces: correctPieces, isCorrect: true)
        var options: [MultipleChoiceOption] = [correct]
        options += distractors(
            from: correctPieces,
            shape: shape,
            pieceCount: pieceCount,
            ambiguity: difficulty.ambiguity,
            needed: 3
        )
        options.shuffle()

        let correctIdx = options.firstIndex(where: \.isCorrect) ?? 0
        return Puzzle(
            shape: shape,
            difficulty: difficulty,
            phase: phase,
            activePieceCount: pieceCount,
            multipleChoiceOptions: options,
            correctOptionIndex: correctIdx
        )
    }

    /// Generates distractor options using progressive similarity based on ambiguity.
    private func distractors(
        from correctPieces: [ShapePiece],
        shape: PuzzleShape,
        pieceCount: Int,
        ambiguity: Double,
        needed: Int
    ) -> [MultipleChoiceOption] {
        var result: [MultipleChoiceOption] = []

        // Distractor 1: Same pieces, all rotated 90°
        let rotated = correctPieces.map { p in
            ShapePiece(
                id: p.id + "-r90",
                vertices: p.vertices,
                solutionRotation: (p.solutionRotation + .pi / 2)
                    .truncatingRemainder(dividingBy: .pi * 2)
            )
        }
        result.append(MultipleChoiceOption(pieces: rotated, isCorrect: false))

        // Distractor 2: Pieces from a different shape with the same piece count
        let otherShapes = library.allShapes.filter {
            $0.id != shape.id && $0.decompositions[pieceCount] != nil
        }
        for other in otherShapes.shuffled().prefix(needed - result.count) {
            if let otherPieces = other.decompositions[pieceCount] {
                result.append(MultipleChoiceOption(pieces: otherPieces, isCorrect: false))
            }
        }

        // Distractor 3 (high ambiguity): Swap one piece with an equivalent from another shape
        if ambiguity > 0.6, result.count < needed, let alt = otherShapes.first,
           let altPieces = alt.decompositions[pieceCount],
           let swapIdx = correctPieces.indices.randomElement() {
            var mixed = correctPieces
            mixed[swapIdx] = altPieces[swapIdx % altPieces.count]
            result.append(MultipleChoiceOption(pieces: mixed, isCorrect: false))
        }

        return Array(result.prefix(needed))
    }
}
