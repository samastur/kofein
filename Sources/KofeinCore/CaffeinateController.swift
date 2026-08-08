import Foundation
import Observation

/// Abstraction over a spawnable caffeinate process so the controller can be
/// tested without launching real processes.
public protocol ProcessRunning: AnyObject {
    /// Called when the process exits on its own (timeout, watched pid gone,
    /// utility finished) or after `terminate()`.
    var onTermination: (() -> Void)? { get set }
    func start(arguments: [String]) throws
    func terminate()
}

/// Starts and stops caffeinate for a profile and tracks whether it is running.
@Observable
public final class CaffeinateController {
    public private(set) var isActive = false
    public private(set) var activeProfile: Profile?
    /// Observed by the UI to update the menubar icon. Called with the new
    /// `isActive` value on every transition, including self-termination.
    @ObservationIgnored public var onStateChange: ((Bool) -> Void)?

    private let makeProcess: () -> ProcessRunning
    private var process: ProcessRunning?

    public init(makeProcess: @escaping () -> ProcessRunning) {
        self.makeProcess = makeProcess
    }

    /// Start caffeinate with the profile's options, replacing any running instance.
    public func activate(_ profile: Profile) throws {
        stopCurrentProcess()
        let newProcess = makeProcess()
        newProcess.onTermination = { [weak self, weak newProcess] in
            guard let self, self.process === newProcess else { return }
            self.process = nil
            self.setActive(false)
        }
        try newProcess.start(arguments: profile.options.arguments)
        process = newProcess
        activeProfile = profile
        setActive(true)
    }

    public func deactivate() {
        guard isActive else { return }
        stopCurrentProcess()
        setActive(false)
    }

    public func toggle(_ profile: Profile) throws {
        if isActive {
            deactivate()
        } else {
            try activate(profile)
        }
    }

    private func stopCurrentProcess() {
        guard let current = process else { return }
        process = nil
        // Detach the handler first: a stop we initiated must not be reported
        // again as an external termination.
        current.onTermination = nil
        current.terminate()
    }

    private func setActive(_ active: Bool) {
        isActive = active
        if !active { activeProfile = nil }
        onStateChange?(active)
    }
}
