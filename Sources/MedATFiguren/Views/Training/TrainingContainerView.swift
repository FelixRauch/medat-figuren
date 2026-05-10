#if canImport(SwiftUI)
import SwiftUI

/// Top-level training view that owns the `PuzzleViewModel` and routes
/// between the phase intro, active puzzle UI, feedback, and transition screens.
public struct TrainingContainerView: View {

    @Environment(AppEnvironment.self) private var env
    @State private var vm: PuzzleViewModel?

    public init() {}

    public var body: some View {
        Group {
            if let vm {
                trainingContent(vm: vm)
            } else {
                ProgressView("Loading…")
                    .task { setupVM() }
            }
        }
        .navigationTitle(env.progress.currentPhase.shortName)
    }

    // MARK: - State routing

    @ViewBuilder
    private func trainingContent(vm: PuzzleViewModel) -> some View {
        switch vm.state {
        case .loading:
            ProgressView("Preparing puzzle…")
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
            Text("Mastery Achieved! 🎉")
                .font(.largeTitle.bold())
        }
    }

    private func setupVM() {
        let viewModel = PuzzleViewModel(env: env)
        viewModel.startSession()
        vm = viewModel
    }
}

#endif // canImport(SwiftUI)
