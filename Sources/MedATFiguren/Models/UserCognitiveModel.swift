import Foundation
import Observation

// MARK: - UserCognitiveModel

/// **Layer 3 — Personal Cognitive Model.**
///
/// Maintains two continuously adapting per-user thresholds:
///
/// * **E-floor** (engagement floor): success rate below which difficulty is reduced immediately.
///   Adapts *fast* — emotional state is volatile.
/// * **P-threshold** (progression threshold): success rate required to advance to the next phase.
///   Adapts *slowly* — skill acquisition is gradual and stable.
///
/// Thresholds start at conservative defaults and are calibrated after the first
/// `calibrationPuzzleCount` attempts, then keep evolving throughout the user's lifetime.
@Observable
public final class UserCognitiveModel: Codable {

    // MARK: - Calibration

    /// Number of puzzles needed before first calibration.
    public static let calibrationPuzzleCount = 20

    public private(set) var isCalibrated: Bool = false
    public private(set) var puzzlesAttemptedForCalibration: Int = 0

    // MARK: - Thresholds

    /// Engagement floor — if recent success rate falls below this the system
    /// lowers difficulty immediately. Default: 0.60.
    public private(set) var engagementFloor: Double = 0.60

    /// Progression threshold — minimum stable success rate for next-phase transition.
    /// Default: 0.78.
    public private(set) var progressionThreshold: Double = 0.78

    // MARK: - Adaptation speeds (asymmetry principle)

    /// E-floor adapts fast to protect against frustration.
    private let eFloorRate: Double = 0.08
    /// P-threshold adapts slowly to require consistent mastery evidence.
    private let pThresholdRate: Double = 0.02

    private let eFloorBounds: ClosedRange<Double>  = 0.45...0.82
    private let pThresholdBounds: ClosedRange<Double> = 0.65...0.92

    // MARK: - Init

    public init() {}

    public func reset() {
        isCalibrated                    = false
        puzzlesAttemptedForCalibration  = 0
        engagementFloor                 = 0.60
        progressionThreshold            = 0.78
    }

    // MARK: - Public API

    /// Update the model after each puzzle result.
    public func update(with result: PuzzleResult, window: PerformanceWindow) {
        if !isCalibrated {
            puzzlesAttemptedForCalibration += 1
            if puzzlesAttemptedForCalibration >= Self.calibrationPuzzleCount {
                calibrate(using: window)
                isCalibrated = true
            }
        } else {
            adapt(using: window)
        }
    }

    /// Returns `true` when the user's success rate has dropped below the E-floor.
    public func isEngagementThreatened(successRate: Double) -> Bool {
        successRate < engagementFloor
    }

    /// Returns `true` when the user meets progression criteria.
    /// Requires at least 10 results in the window for statistical reliability.
    public func isEligibleForProgression(window: PerformanceWindow) -> Bool {
        guard window.sampleCount >= 10 else { return false }
        return window.successRate >= progressionThreshold
    }

    // MARK: - Private Adaptation

    private func calibrate(using window: PerformanceWindow) {
        let observed = window.successRate
        // E-floor = 85 % of calibrated rate (just below comfort zone)
        engagementFloor = (observed * 0.85).clamped(to: eFloorBounds)
        // P-threshold = 5 % above calibrated rate (requires improvement to advance)
        progressionThreshold = (observed * 1.05).clamped(to: pThresholdBounds)
    }

    private func adapt(using window: PerformanceWindow) {
        let observed = window.successRate

        // E-floor: fast convergence toward 80 % of observed rate
        let targetEFloor = (observed * 0.80).clamped(to: eFloorBounds)
        engagementFloor += eFloorRate * (targetEFloor - engagementFloor)
        engagementFloor  = engagementFloor.clamped(to: eFloorBounds)

        // P-threshold: slow convergence toward observed + 3 % (require consistent mastery)
        if window.sampleCount >= 15 {
            let targetPThreshold = (observed * 1.03).clamped(to: pThresholdBounds)
            progressionThreshold += pThresholdRate * (targetPThreshold - progressionThreshold)
            progressionThreshold  = progressionThreshold.clamped(to: pThresholdBounds)
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case isCalibrated, puzzlesAttemptedForCalibration
        case engagementFloor, progressionThreshold
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(isCalibrated, forKey: .isCalibrated)
        try c.encode(puzzlesAttemptedForCalibration, forKey: .puzzlesAttemptedForCalibration)
        try c.encode(engagementFloor, forKey: .engagementFloor)
        try c.encode(progressionThreshold, forKey: .progressionThreshold)
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isCalibrated = try c.decode(Bool.self, forKey: .isCalibrated)
        puzzlesAttemptedForCalibration = try c.decode(Int.self, forKey: .puzzlesAttemptedForCalibration)
        engagementFloor = try c.decode(Double.self, forKey: .engagementFloor)
        progressionThreshold = try c.decode(Double.self, forKey: .progressionThreshold)
    }
}
