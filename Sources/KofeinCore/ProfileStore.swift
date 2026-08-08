import Foundation
import Observation

public enum ProfileStoreError: Error, Equatable {
    case cannotDeleteLastProfile
    case profileNotFound
}

/// Persistent collection of profiles with a designated default.
///
/// Invariants: at least one profile always exists, and `defaultProfileID`
/// always refers to a stored profile. The store loads from `fileURL` on init
/// and saves after every mutation. A missing or unreadable file is replaced
/// by a seeded "keep awake" profile.
@Observable
public final class ProfileStore {
    public private(set) var profiles: [Profile] = []
    public private(set) var defaultProfileID: UUID

    private let fileURL: URL

    private struct Document: Codable {
        var version: Int
        var defaultProfileID: UUID
        var profiles: [Profile]
    }

    public init(fileURL: URL, seedProfileName: String = "Keep Awake") {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let document = try? JSONDecoder().decode(Document.self, from: data),
           !document.profiles.isEmpty,
           document.profiles.contains(where: { $0.id == document.defaultProfileID }) {
            profiles = document.profiles
            defaultProfileID = document.defaultProfileID
        } else {
            let seeded = Profile(name: seedProfileName, options: .keepAwake)
            profiles = [seeded]
            defaultProfileID = seeded.id
            // First launch (or corrupt file): persist the seed, but a save
            // failure must not prevent the app from running in memory.
            try? save()
        }
    }

    public var defaultProfile: Profile {
        profiles.first(where: { $0.id == defaultProfileID }) ?? profiles[0]
    }

    public func add(_ profile: Profile) throws {
        profiles.append(profile)
        try save()
    }

    public func update(_ profile: Profile) throws {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            throw ProfileStoreError.profileNotFound
        }
        profiles[index] = profile
        try save()
    }

    public func delete(id: UUID) throws {
        guard profiles.contains(where: { $0.id == id }) else {
            throw ProfileStoreError.profileNotFound
        }
        guard profiles.count > 1 else {
            throw ProfileStoreError.cannotDeleteLastProfile
        }
        profiles.removeAll { $0.id == id }
        if defaultProfileID == id {
            defaultProfileID = profiles[0].id
        }
        try save()
    }

    public func setDefault(id: UUID) throws {
        guard profiles.contains(where: { $0.id == id }) else {
            throw ProfileStoreError.profileNotFound
        }
        defaultProfileID = id
        try save()
    }

    private func save() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let document = Document(version: 1, defaultProfileID: defaultProfileID, profiles: profiles)
        try encoder.encode(document).write(to: fileURL, options: .atomic)
    }
}
