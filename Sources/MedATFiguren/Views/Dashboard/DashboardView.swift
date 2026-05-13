#if canImport(SwiftUI)
import SwiftUI

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
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func dashboardContent(vm: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                summaryGrid(vm: vm)
                phaseSection(vm: vm)
                adaptiveSection(vm: vm)
                recentSection(vm: vm)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Summary grid

    private func summaryGrid(vm: DashboardViewModel) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            StatCard(title: "Puzzles", value: "\(vm.totalAttempted)",
                     icon: "puzzlepiece.fill", color: .indigo)
            StatCard(title: "Accuracy", value: "\(Int(vm.overallAccuracy * 100))%",
                     icon: "target", color: .green)
            StatCard(title: "Sessions", value: "\(vm.totalSessions)",
                     icon: "clock.fill", color: .orange)
            StatCard(title: "Phase", value: "\(vm.currentPhase.rawValue) / 5",
                     icon: "flag.fill", color: .purple)
        }
    }

    // MARK: - Phase section

    private func phaseSection(vm: DashboardViewModel) -> some View {
        SectionCard(title: "Phase Progress", icon: "chart.bar.fill") {
            VStack(spacing: 14) {
                ForEach(vm.phaseBreakdown) { stats in
                    PhaseProgressRow(stats: stats)
                }
            }
        }
    }

    // MARK: - Adaptive model section

    private func adaptiveSection(vm: DashboardViewModel) -> some View {
        SectionCard(title: "Adaptive Model", icon: "brain.head.profile") {
            if vm.isCalibrated {
                VStack(spacing: 14) {
                    ThresholdRow(
                        label: "Engagement Floor",
                        value: vm.engagementFloor,
                        color: .orange,
                        tooltip: "Below this triggers difficulty reduction."
                    )
                    Divider()
                    ThresholdRow(
                        label: "Progression Threshold",
                        value: vm.progressionThreshold,
                        color: .indigo,
                        tooltip: "Above this triggers phase advancement."
                    )
                }
            } else {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Calibrating… \(env.cognitiveModel.puzzlesAttemptedForCalibration)/\(UserCognitiveModel.calibrationPuzzleCount) puzzles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Recent results section

    private func recentSection(vm: DashboardViewModel) -> some View {
        SectionCard(title: "Recent Results", icon: "chart.line.uptrend.xyaxis") {
            if vm.recentResults.isEmpty {
                ContentUnavailableView {
                    Label("No puzzles yet", systemImage: "puzzlepiece")
                } description: {
                    Text("Complete your first puzzle to see results here.")
                }
                .frame(height: 100)
            } else {
                ProgressChartView(results: vm.recentResults)
                    .frame(height: 120)
            }
        }
    }
}

// MARK: - SectionCard

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            content
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            Spacer(minLength: 0)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - PhaseProgressRow

private struct PhaseProgressRow: View {
    let stats: PhaseStats

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(stats.isCurrentPhase ? Color.indigo : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                    Text(stats.phase.shortName)
                        .font(.subheadline.weight(stats.isCurrentPhase ? .semibold : .regular))
                    if stats.isCurrentPhase {
                        Text("Now")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.15), in: Capsule())
                            .foregroundStyle(.indigo)
                    }
                }
                Spacer()
                Text(stats.attempted > 0 ? "\(Int(stats.accuracy * 100))%" : "—")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(stats.attempted > 0 ? .primary : .secondary)
            }
            ProgressView(value: stats.accuracy)
                .tint(stats.isCurrentPhase ? .indigo : .secondary)
        }
    }
}

// MARK: - ThresholdRow

private struct ThresholdRow: View {
    let label: String
    let value: Double
    let color: Color
    let tooltip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(color)
            }
            ProgressView(value: value).tint(color)
            Text(tooltip)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#endif // canImport(SwiftUI)
