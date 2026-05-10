#if canImport(SwiftUI)
import SwiftUI

/// Phase 3 — Mental Prediction Step.
///
/// Before any manipulation, the user must select the correct orientation for each
/// piece using a segmented picker. Once all pieces have a prediction the user
/// confirms, and the system records accuracy before switching to assembly.
public struct PredictionStepView: View {

    public let puzzle: Puzzle
    @Bindable public var vm: PuzzleViewModel

    private let pieces: [ShapePiece]
    private let rotationOptions: [Double] = [0, .pi / 2, .pi, 3 * .pi / 2]
    private let rotationLabels: [String]  = ["0°", "90°", "180°", "270°"]

    public init(puzzle: Puzzle, vm: PuzzleViewModel) {
        self.puzzle = puzzle
        self.vm = vm
        self.pieces = puzzle.assemblyPieces ?? []
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    instructionBanner
                    targetShapeCard
                    piecePredictionList
                    confirmButton
                }
                .padding()
            }
            .navigationTitle("Mental Prediction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { PhaseIndicatorView(phase: puzzle.phase) }
        }
    }

    // MARK: - Sub-views

    private var instructionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Predict first — then verify", systemImage: "brain.head.profile")
                .font(.headline)
            Text("For each piece, choose the rotation that correctly fits the target shape. No touching the pieces yet!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var targetShapeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Shape")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            TargetShapeView(shape: puzzle.shape)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var piecePredictionList: some View {
        VStack(spacing: 20) {
            ForEach(Array(pieces.enumerated()), id: \.element.id) { index, piece in
                PiecePredictionRow(
                    pieceIndex: index + 1,
                    piece: piece,
                    rotationOptions: rotationOptions,
                    rotationLabels: rotationLabels,
                    selectedRotation: vm.predictedRotations[piece.id],
                    onSelect: { rotation in
                        vm.setPredictedRotation(rotation, forPieceID: piece.id)
                    }
                )
            }
        }
    }

    private var allPredicted: Bool {
        pieces.allSatisfy { vm.predictedRotations[$0.id] != nil }
    }

    private var confirmButton: some View {
        Button {
            vm.submitPrediction()
        } label: {
            Label("Confirm Prediction", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!allPredicted)
        .tint(.indigo)
        .accessibilityLabel("Confirm your mental prediction")
    }
}

// MARK: - PiecePredictionRow

private struct PiecePredictionRow: View {
    let pieceIndex: Int
    let piece: ShapePiece
    let rotationOptions: [Double]
    let rotationLabels: [String]
    let selectedRotation: Double?
    let onSelect: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Piece \(pieceIndex)")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 12) {
                // Piece preview
                ShapePathView(vertices: piece.vertices)
                    .fill(Color.indigo.opacity(0.5))
                    .overlay(ShapePathView(vertices: piece.vertices).stroke(Color.indigo, lineWidth: 1.5))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.radians(selectedRotation ?? 0))
                    .animation(.spring(response: 0.3), value: selectedRotation)

                // Rotation picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Select orientation:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                        ForEach(Array(zip(rotationOptions, rotationLabels)), id: \.0) { angle, label in
                            Button(label) {
                                onSelect(angle)
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedRotation == angle ? .indigo : .gray)
                            .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#endif // canImport(SwiftUI)
