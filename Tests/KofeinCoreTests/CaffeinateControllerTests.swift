import Foundation
import Testing
@testable import KofeinCore

private final class FakeProcess: ProcessRunning {
    var onTermination: (() -> Void)?
    var startedArguments: [String]?
    var terminated = false
    func start(arguments: [String]) throws { startedArguments = arguments }
    func terminate() {
        terminated = true
        onTermination?()
    }
}

private func makeController() -> (CaffeinateController, () -> FakeProcess?) {
    var current: FakeProcess?
    let controller = CaffeinateController {
        let process = FakeProcess()
        current = process
        return process
    }
    return (controller, { current })
}

private let profile = Profile(name: "Test", options: .keepAwake)

@Test func activateStartsCaffeinateWithProfileArguments() throws {
    let (controller, currentProcess) = makeController()
    try controller.activate(profile)
    #expect(controller.isActive)
    #expect(controller.activeProfile == profile)
    #expect(currentProcess()?.startedArguments == ["-d", "-i"])
}

@Test func toggleTwiceStartsThenStops() throws {
    let (controller, currentProcess) = makeController()
    try controller.toggle(profile)
    #expect(controller.isActive)
    let first = currentProcess()
    try controller.toggle(profile)
    #expect(!controller.isActive)
    #expect(controller.activeProfile == nil)
    #expect(first?.terminated == true)
}

@Test func activatingWhileActiveRestartsWithNewArguments() throws {
    let (controller, currentProcess) = makeController()
    try controller.activate(profile)
    let first = currentProcess()
    let other = Profile(name: "Other", options: CaffeinateOptions(preventIdleSleep: true, preventDiskSleep: true))
    try controller.activate(other)
    #expect(first?.terminated == true)
    #expect(controller.isActive)
    #expect(controller.activeProfile == other)
    #expect(currentProcess()?.startedArguments == ["-i", "-m"])
}

@Test func externalTerminationDeactivatesAndNotifies() throws {
    let (controller, currentProcess) = makeController()
    var states: [Bool] = []
    controller.onStateChange = { states.append($0) }
    try controller.activate(profile)
    currentProcess()?.onTermination?() // e.g. -t timeout expired
    #expect(!controller.isActive)
    #expect(controller.activeProfile == nil)
    #expect(states == [true, false])
}

@Test func activateWithTimeoutPassesTArgument() throws {
    let (controller, currentProcess) = makeController()
    try controller.activate(profile, timeoutSeconds: 300)
    #expect(currentProcess()?.startedArguments == ["-d", "-i", "-t", "300"])
}

@Test func toggleOnWithTimeoutPassesTArgument() throws {
    let (controller, currentProcess) = makeController()
    try controller.toggle(profile, timeoutSeconds: 60)
    #expect(currentProcess()?.startedArguments == ["-d", "-i", "-t", "60"])
}

@Test func timeoutIsIgnoredForIncompatibleProfile() throws {
    let (controller, currentProcess) = makeController()
    let waiting = Profile(name: "Wait", options: CaffeinateOptions(waitForPID: 99))
    try controller.activate(waiting, timeoutSeconds: 300)
    #expect(currentProcess()?.startedArguments == ["-w", "99"])
}

@Test func deactivateDoesNotDoubleNotify() throws {
    let (controller, _) = makeController()
    var states: [Bool] = []
    controller.onStateChange = { states.append($0) }
    try controller.activate(profile)
    controller.deactivate()
    controller.deactivate() // no-op when inactive
    #expect(states == [true, false])
}
