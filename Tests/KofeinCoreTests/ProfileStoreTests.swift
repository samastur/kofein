import Foundation
import Testing
@testable import KofeinCore

private func tempURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("kofein-tests-\(UUID().uuidString)")
        .appendingPathComponent("profiles.json")
}

@Test func emptyStoreSeedsDefaultKeepAwakeProfile() {
    let store = ProfileStore(fileURL: tempURL(), seedProfileName: "Keep Awake")
    #expect(store.profiles.count == 1)
    #expect(store.profiles[0].name == "Keep Awake")
    #expect(store.profiles[0].options == .keepAwake)
    #expect(store.defaultProfileID == store.profiles[0].id)
    #expect(store.defaultProfile == store.profiles[0])
}

@Test func storePersistsAcrossInstances() throws {
    let url = tempURL()
    let store = ProfileStore(fileURL: url)
    let profile = Profile(name: "Coffee break",
                          options: CaffeinateOptions(preventIdleSleep: true, timeoutSeconds: 900))
    try store.add(profile)
    try store.setDefault(id: profile.id)
    let reloaded = ProfileStore(fileURL: url)
    #expect(reloaded.profiles == store.profiles)
    #expect(reloaded.defaultProfileID == profile.id)
}

@Test func updateReplacesProfileByID() throws {
    let store = ProfileStore(fileURL: tempURL())
    var profile = Profile(name: "Original", options: CaffeinateOptions())
    try store.add(profile)
    profile.name = "Renamed"
    profile.options.preventDiskSleep = true
    try store.update(profile)
    #expect(store.profiles.first(where: { $0.id == profile.id }) == profile)
}

@Test func deletingDefaultPromotesAnotherProfile() throws {
    let store = ProfileStore(fileURL: tempURL())
    let seeded = store.defaultProfile
    let other = Profile(name: "Other", options: CaffeinateOptions())
    try store.add(other)
    try store.delete(id: seeded.id)
    #expect(store.profiles == [other])
    #expect(store.defaultProfileID == other.id)
}

@Test func deletingLastProfileThrows() {
    let store = ProfileStore(fileURL: tempURL())
    #expect(throws: ProfileStoreError.cannotDeleteLastProfile) {
        try store.delete(id: store.defaultProfileID)
    }
}

@Test func operatingOnUnknownIDThrows() {
    let store = ProfileStore(fileURL: tempURL())
    let ghost = Profile(name: "Ghost", options: CaffeinateOptions())
    #expect(throws: ProfileStoreError.profileNotFound) { try store.update(ghost) }
    #expect(throws: ProfileStoreError.profileNotFound) { try store.delete(id: ghost.id) }
    #expect(throws: ProfileStoreError.profileNotFound) { try store.setDefault(id: ghost.id) }
}

@Test func corruptFileIsReplacedBySeed() throws {
    let url = tempURL()
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: url)
    let store = ProfileStore(fileURL: url)
    #expect(store.profiles.count == 1)
    #expect(store.defaultProfileID == store.profiles[0].id)
}
