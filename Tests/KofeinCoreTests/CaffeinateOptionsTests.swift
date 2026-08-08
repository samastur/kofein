import Foundation
import Testing
@testable import KofeinCore

@Test func defaultOptionsProduceNoArguments() {
    #expect(CaffeinateOptions().arguments.isEmpty)
}

@Test func flagOptionsMapToSingleLetterFlags() {
    var o = CaffeinateOptions()
    o.preventDisplaySleep = true
    o.preventIdleSleep = true
    o.preventDiskSleep = true
    o.preventSystemSleepOnAC = true
    o.declareUserActive = true
    #expect(o.arguments == ["-d", "-i", "-m", "-s", "-u"])
}

@Test func timeoutAndPIDProduceValueArguments() {
    var o = CaffeinateOptions()
    o.timeoutSeconds = 600
    o.waitForPID = 1234
    #expect(o.arguments == ["-t", "600", "-w", "1234"])
}

@Test func utilityCommandIsWrappedInShell() {
    var o = CaffeinateOptions(preventIdleSleep: true)
    o.utilityCommand = "make build && say done"
    #expect(o.arguments == ["-i", "/bin/sh", "-c", "make build && say done"])
}

@Test func blankUtilityCommandIsIgnored() {
    var o = CaffeinateOptions()
    o.utilityCommand = "   "
    #expect(o.arguments.isEmpty)
}

@Test func keepAwakePreventsDisplayAndIdleSleep() {
    #expect(CaffeinateOptions.keepAwake.arguments == ["-d", "-i"])
}

@Test func optionsRoundTripThroughJSON() throws {
    let o = CaffeinateOptions(preventDisplaySleep: true, timeoutSeconds: 42, utilityCommand: "true")
    let data = try JSONEncoder().encode(o)
    #expect(try JSONDecoder().decode(CaffeinateOptions.self, from: data) == o)
}
