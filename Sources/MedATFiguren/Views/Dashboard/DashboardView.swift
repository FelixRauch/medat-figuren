#if canImport(SwiftUI)
import SwiftUI

/// Dashboard showing overall progress, per-phase accuracy, and the adaptive model state.
public struct DashboardView: View {

    @Environment(AppEnvironment.self) private var env
    @State private var vm: DashboardViewModel?

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    dashboardContent(vm: vm)
                } else {
                    ProgressView()
                        .onAppear { vm = DashboardViewModel(env: env) }
                }
            }
            .navigationTitle("My Progress")
        }
    }

    @ViewBuilder
    private func dashboardContent(vm: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCards(vm: vm)
                phaseProgressSection(vm: vm)
                adaptiveModelSection(vm: vm)
                recentResultsSection(vm: vm)
            }
            .padding()
        }
    }

    // MARK: - Summary cards

    private func summaryCards(vm: DashboardViewModel) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Puzzles", value: "\(vm.totalAttempted)", icon: "puzzlepiece.fill", color: .indigo)
            StatCard(title: "Accuracy", value: "\(Int(vm.overallAccuracy * 100))%", icon: "target", color: .green)
            StatCard(title: "Sessions", value: "\(vm.totalSessions)", icon: "clock.fill", color: .orange)
            StatCard(title: "Phase", value: "\(vm.currentPhase.rawValue) of 5", icon: "flag.fill", color: .purple)
        }
    }

    // MARK: - Phase progress

    private func phaseProgressSection(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phase Progress")
                .font(.headline)

            ForEach(vm.phaseBreakdown) { stats in
                PhaseProgressRow(stats: stats)
            }
        }
    }

    // MARK: - Adaptive model

    private func adaptiveModelSection(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adaptive Model")
                .font(.headline)

            if vm.isCalibrated {
                VStack(spacing: 10) {
                    ThresholdRow(
                        label: "Engagement Floor",
                        value: vm.engagementFloor,
                        color: .orange,
                        tooltip: "Success rate below this triggers difficulty reduction."
                    )
                    ThresholdRow(
                        label: "Progression Threshold",
                        value: vm.progressionThreshold,
                        color: .indigo,
                        tooltip: "Sustained rate above this triggers phase advancement."
                    )
                }
            } else {
                Label("Calibrating… (\(env.cognitiveModel.puzzlesAttemptedForCalibration)/\(UserCognitiveModel.calibrationPuzzleCount) puzzles)", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recent results

    private func recentResultsSection(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Results")
                .font(.headline)

            if vm.recentResults.isEmpty {
                Text("No puzzles completed yet. Start training!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ProgressChartView(results: vm.recentResults)
                    .frame(height: 120)
            }
        }
    }
}

// MARK: - Supporting components

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PhaseProgressRow: View {
    let stats: PhaseStats

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(stats.isCurrentPhase ? Color.indigo : Color(.systemGray4))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(stats.phase.shortName)
                        .font(.subheadline.weight(stats.isCurrentPhase ? .semibold : .regular))
                    if stats.isCurrentPhase {
                        Text("Current")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.15), in: Capsule())
                            .foregroundStyle(.indigo)
                    }
                    Spacer()
                    Text(stats.attempted > 0 ? "\(Int(stats.accuracy * 100))%" : "—")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: stats.accuracy)
                    .tint(stats.isCurrentPhase ? .indigo : .secondary)
            }
        }
    }
}

private struct ThresholdRow: View {
    let label: String
    let value: Double
    let color: Color
    let tooltip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(color)
            }
            ProgressView(value: value)
                .tint(color)
            Text(tooltip)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#endif // canImport(SwiftUI)
