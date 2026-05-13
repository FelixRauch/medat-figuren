#if canImport(SwiftUI)
import SwiftUI

public struct TrainingContainerView: View {

    @Environment(AppEnvironment.self) private var env
    @State private var vm: PuzzleViewModel?

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    trainingContent(vm: vm)
                } else {
                    loadingView
                        .task { setupVM() }
                }
            }
            .navigationTitle(env.progress.currentPhase.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhaseIndicatorView(phase: env.progress.currentPhase)
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text("Preparing puzzle…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - State routing

    @ViewBuilder
    private func trainingContent(vm: PuzzleViewModel) -> some View {
        switch vm.state {
        case .loading:
            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                Text("Generating puzzle…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .onAppear { vm.loadNextPuzzle() }

        case .predicting:
            if let puzzle = vm.currentPuzzle {
                PredictionStepView(puzzle: puzzle, vm: vm)
            }

        case .assembling:
            if let puzzle = vm.currentPuzzle {
                AssemblyCanvasView(puzzle: puzzle, vm: vm)
            }

        case .multipleChoice:
            if let puzzle = vm.currentPuzzle {
                MultipleChoiceView(puzzle: puzzle, vm: vm)
            }

        case .showingFeedback(let isCorrect):
            PuzzleFeedbackView(isCorrect: isCorrect) {
                vm.loadNextPuzzle()
            }

        case .phaseTransitionAvailable:
            PhaseTransitionView(
                from: env.progress.currentPhase.previous ?? env.progress.currentPhase,
                to: env.progress.currentPhase.next ?? env.progress.currentPhase
            ) {
                vm.confirmPhaseTransition()
            }

        case .finished:
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)
                Text("Mastery Achieved!")
                    .font(.largeTitle.bold())
                Text("You've completed all 5 phases of MedAT Figuren training.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func setupVM() {
        let viewModel = PuzzleViewModel(env: env)
        viewModel.startSession()
        vm = viewModel
    }
}

#endif // canImport(SwiftUI)
