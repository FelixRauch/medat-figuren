import Foundation

/// Reads and writes user data to the app's Documents directory using JSON.
public final class PersistenceManager {

    public static let shared = PersistenceManager()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - UserProgress

    public func saveProgress(_ progress: UserProgress) throws {
        let data = try encoder.encode(progress)
        try data.write(to: progressURL, options: .atomic)
    }

    public func loadProgress() throws -> UserProgress {
        guard fileManager.fileExists(atPath: progressURL.path) else {
            return UserProgress()
        }
        let data = try Data(contentsOf: progressURL)
        return try decoder.decode(UserProgress.self, from: data)
    }

    // MARK: - UserCognitiveModel

    public func saveCognitiveModel(_ model: UserCognitiveModel) throws {
        let data = try encoder.encode(model)
        try data.write(to: cognitiveModelURL, options: .atomic)
    }

    public func loadCognitiveModel() throws -> UserCognitiveModel {
        guard fileManager.fileExists(atPath: cognitiveModelURL.path) else {
            return UserCognitiveModel()
        }
        let data = try Data(contentsOf: cognitiveModelURL)
        return try decoder.decode(UserCognitiveModel.self, from: data)
    }

    // MARK: - URLs

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var progressURL: URL {
        documentsURL.appendingPathComponent("user_progress.json")
    }

    private var cognitiveModelURL: URL {
        documentsURL.appendingPathComponent("cognitive_model.json")
    }
}
