import Foundation
import Testing
@testable import KofeinCore

@Test func defaultOptionsProduceNoArguments() {
    #expect(CaffeinateOptions().arguments().isEmpty)
}

@Test func flagOptionsMapToSingleLetterFlags() {
    var o = CaffeinateOptions()
    o.preventDisplaySleep = true
    o.preventIdleSleep = true
    o.preventDiskSleep = true
    o.preventSystemSleepOnAC = true
    o.declareUserActive = true
    #expect(o.arguments() == ["-d", "-i", "-m", "-s", "-u"])
}

@Test func pidProducesValueArgument() {
    var o = CaffeinateOptions()
    o.waitForPID = 1234
    #expect(o.arguments() == ["-w", "1234"])
}

@Test func utilityCommandIsWrappedInShell() {
    var o = CaffeinateOptions(preventIdleSleep: true)
    o.utilityCommand = "make build && say done"
    #expect(o.arguments() == ["-i", "/bin/sh", "-c", "make build && say done"])
}

@Test func blankUtilityCommandIsIgnored() {
    var o = CaffeinateOptions()
    o.utilityCommand = "   "
    #expect(o.arguments().isEmpty)
}

@Test func keepAwakePreventsDisplayAndIdleSleep() {
    #expect(CaffeinateOptions.keepAwake.arguments() == ["-d", "-i"])
}

@Test func optionsRoundTripThroughJSON() throws {
    let o = CaffeinateOptions(preventDisplaySleep: true, waitForPID: 7, utilityCommand: "true")
    let data = try JSONEncoder().encode(o)
    #expect(try JSONDecoder().decode(CaffeinateOptions.self, from: data) == o)
}

@Test func legacyProfileJSONWithTimeoutStillDecodes() throws {
    let legacy = Data("""
    {"preventDisplaySleep":true,"preventIdleSleep":true,"preventDiskSleep":false,
     "preventSystemSleepOnAC":false,"declareUserActive":false,"timeoutSeconds":900}
    """.utf8)
    let o = try JSONDecoder().decode(CaffeinateOptions.self, from: legacy)
    #expect(o == CaffeinateOptions.keepAwake)
}

@Test func timeoutArgumentIsAppendedWhenSupported() {
    let o = CaffeinateOptions.keepAwake
    #expect(o.supportsTimeout)
    #expect(o.arguments(timeoutSeconds: 300) == ["-d", "-i", "-t", "300"])
}

@Test func waitingOnPIDIsIncompatibleWithTimeout() {
    var o = CaffeinateOptions()
    o.waitForPID = 42
    #expect(!o.supportsTimeout)
    #expect(o.arguments(timeoutSeconds: 300) == ["-w", "42"])
}

@Test func utilityCommandIsIncompatibleWithTimeout() {
    var o = CaffeinateOptions()
    o.utilityCommand = "sleep 5"
    #expect(!o.supportsTimeout)
    #expect(o.arguments(timeoutSeconds: 300) == ["/bin/sh", "-c", "sleep 5"])
}

@Test func blankUtilityCommandStaysCompatibleWithTimeout() {
    var o = CaffeinateOptions()
    o.utilityCommand = "  "
    #expect(o.supportsTimeout)
    #expect(o.arguments(timeoutSeconds: 60) == ["-t", "60"])
}
