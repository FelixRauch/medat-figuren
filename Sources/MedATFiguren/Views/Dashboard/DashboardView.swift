#if canImport(SwiftUI)
import SwiftUI

public struct DashboardView: View {

    @Environment(AppEnvironment.self) private var env
    @State private var vm: DashboardViewModel?

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if let vm { content(vm: vm) }
                else { ProgressView().task { vm = DashboardViewModel(env: env) } }
            }
            .navigationTitle("Progress")
        }
    }

    @ViewBuilder
    private func content(vm: DashboardViewModel) -> some View {
        List {
            // ── Stats grid ─────────────────────────────────────────
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MiniStatCard("Puzzles",  value: "\(vm.totalAttempted)",            icon: "puzzlepiece.fill", tint: .indigo)
                    MiniStatCard("Accuracy", value: "\(Int(vm.overallAccuracy * 100))%", icon: "target",           tint: .green)
                    MiniStatCard("Sessions", value: "\(vm.totalSessions)",             icon: "clock.fill",       tint: .orange)
                    MiniStatCard("Phase",    value: "\(vm.currentPhase.rawValue) / 5", icon: "flag.fill",        tint: .purple)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical, 4)
            }

            // ── Phase progress ─────────────────────────────────────
            Section("Phase Progress") {
                ForEach(vm.phaseBreakdown) { stats in
                    PhaseRow(stats: stats)
                }
            }

            // ── Adaptive model ─────────────────────────────────────
            Section("Adaptive Model") {
                if vm.isCalibrated {
                    ThresholdRow(label: "Engagement Floor",      value: vm.engagementFloor,        tint: .orange,
                                 detail: "Below this → difficulty reduction")
                    ThresholdRow(label: "Progression Threshold", value: vm.progressionThreshold,   tint: .indigo,
                                 detail: "Above this → phase advancement")
                } else {
                    Label {
                        Text("Calibrating… \(env.cognitiveModel.puzzlesAttemptedForCalibration)/\(UserCognitiveModel.calibrationPuzzleCount) puzzles")
                            .foregroundStyle(.secondary)
                    } icon: {
                        ProgressView().controlSize(.small)
                    }
                }
            }

            // ── Recent results ─────────────────────────────────────
            Section("Recent Results") {
                if vm.recentResults.isEmpty {
                    ContentUnavailableView("No puzzles yet",
                        systemImage: "puzzlepiece",
                        description: Text("Complete your first puzzle to see results."))
                        .listRowBackground(Color.clear)
                } else {
                    ProgressChartView(results: vm.recentResults)
                        .frame(height: 110)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - MiniStatCard

private struct MiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    init(_ title: String, value: String, icon: String, tint: Color) {
        self.title = title; self.value = value; self.icon = icon; self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - PhaseRow

private struct PhaseRow: View {
    let stats: PhaseStats

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(stats.isCurrentPhase ? Color.indigo : Color(.tertiaryLabel))
                    .frame(width: 7, height: 7)
                Text(stats.phase.shortName)
                    .font(.subheadline.weight(stats.isCurrentPhase ? .semibold : .regular))
                if stats.isCurrentPhase {
                    Text("Current")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.indigo)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.indigo.opacity(0.12), in: Capsule())
                }
                Spacer()
                Text(stats.attempted > 0 ? "\(Int(stats.accuracy * 100))%" : "—")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: stats.accuracy)
                .tint(stats.isCurrentPhase ? .indigo : Color(.tertiaryLabel))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - ThresholdRow

private struct ThresholdRow: View {
    let label: String
    let value: Double
    let tint: Color
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(tint)
            }
            ProgressView(value: value).tint(tint)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#endif // canImport(SwiftUI)
