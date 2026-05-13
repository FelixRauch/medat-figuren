import Foundation
import Observation

/// Persists all user-facing progress: current phase, puzzle history, session metadata.
@Observable
public final class UserProgress: Codable {

    public private(set) var currentPhase: LearningPhase = .perceptualOnboarding
    public private(set) var results: [PuzzleResult] = []
    public private(set) var totalSessionCount: Int = 0
    public private(set) var lastSessionDate: Date?
    public private(set) var phaseEntryDates: [LearningPhase: Date] = [
        .perceptualOnboarding: Date()
    ]

    public init() {}

    // MARK: - Mutations

    public func recordResult(_ result: PuzzleResult) {
        results.append(result)
    }

    /// Advances to the next phase. Ignores the call if `phase` is not the immediate successor.
    public func advanceToPhase(_ phase: LearningPhase) {
        guard phase == currentPhase.next else { return }
        currentPhase = phase
        phaseEntryDates[phase] = Date()
    }

    public func startSession() {
        totalSessionCount += 1
        lastSessionDate = Date()
    }

    public func reset() {
        currentPhase      = .perceptualOnboarding
        results           = []
        totalSessionCount = 0
        lastSessionDate   = nil
        phaseEntryDates   = [.perceptualOnboarding: Date()]
    }

    // MARK: - Queries

    /// Recent results, optionally filtered by phase. Most recent last.
    public func recentResults(count: Int = 20, for phase: LearningPhase? = nil) -> [PuzzleResult] {
        let filtered = phase.map { p in results.filter { $0.phase == p } } ?? results
        return Array(filtered.suffix(count))
    }

    public var totalPuzzlesAttempted: Int { results.count }
    public var totalCorrect: Int { results.filter(\.isCorrect).count }
    public var overallAccuracy: Double {
        guard totalPuzzlesAttempted > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalPuzzlesAttempted)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case currentPhase, results, totalSessionCount, lastSessionDate
        case phaseEntryDatesKeys, phaseEntryDatesValues
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(currentPhase, forKey: .currentPhase)
        try c.encode(results, forKey: .results)
        try c.encode(totalSessionCount, forKey: .totalSessionCount)
        try c.encodeIfPresent(lastSessionDate, forKey: .lastSessionDate)
        let sorted = phaseEntryDates.sorted { $0.key.rawValue < $1.key.rawValue }
        try c.encode(sorted.map(\.key), forKey: .phaseEntryDatesKeys)
        try c.encode(sorted.map(\.value), forKey: .phaseEntryDatesValues)
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentPhase = try c.decode(LearningPhase.self, forKey: .currentPhase)
        results = try c.decode([PuzzleResult].self, forKey: .results)
        totalSessionCount = try c.decode(Int.self, forKey: .totalSessionCount)
        lastSessionDate = try c.decodeIfPresent(Date.self, forKey: .lastSessionDate)
        let keys = try c.decode([LearningPhase].self, forKey: .phaseEntryDatesKeys)
        let values = try c.decode([Date].self, forKey: .phaseEntryDatesValues)
        phaseEntryDates = Dictionary(uniqueKeysWithValues: zip(keys, values))
    }
}
