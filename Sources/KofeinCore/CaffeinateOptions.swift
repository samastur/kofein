import Foundation

/// One combination of `/usr/bin/caffeinate` options.
///
/// Mirrors the option surface of caffeinate(8): the five assertion flags,
/// `-w pid`, and the optional trailing utility command. The timeout (`-t`)
/// is deliberately *not* part of a profile — it is a session-level choice
/// passed to `arguments(timeoutSeconds:)`, because a profile that waits on
/// a process or a command must not be cut short by a timeout (and macOS
/// ignores `-t` in those cases anyway).
public struct CaffeinateOptions: Codable, Equatable, Sendable {
    /// `-d` — prevent the display from sleeping.
    public var preventDisplaySleep = false
    /// `-i` — prevent the system from idle sleeping.
    public var preventIdleSleep = false
    /// `-m` — prevent the disk from idle sleeping.
    public var preventDiskSleep = false
    /// `-s` — prevent system sleep (effective on AC power only).
    public var preventSystemSleepOnAC = false
    /// `-u` — declare that the user is active; turns the display on.
    public var declareUserActive = false
    /// `-w` — release the assertions when this process exits.
    public var waitForPID: Int32?
    /// Trailing utility: caffeinate holds the assertions while the command
    /// runs. Executed through `/bin/sh -c` so shell quoting works.
    public var utilityCommand: String?

    public init(
        preventDisplaySleep: Bool = false,
        preventIdleSleep: Bool = false,
        preventDiskSleep: Bool = false,
        preventSystemSleepOnAC: Bool = false,
        declareUserActive: Bool = false,
        waitForPID: Int32? = nil,
        utilityCommand: String? = nil
    ) {
        self.preventDisplaySleep = preventDisplaySleep
        self.preventIdleSleep = preventIdleSleep
        self.preventDiskSleep = preventDiskSleep
        self.preventSystemSleepOnAC = preventSystemSleepOnAC
        self.declareUserActive = declareUserActive
        self.waitForPID = waitForPID
        self.utilityCommand = utilityCommand
    }

    // Explicit keys: old profile files may carry a removed "timeoutSeconds"
    // key, which the decoder ignores because it is not listed here.
    private enum CodingKeys: String, CodingKey {
        case preventDisplaySleep, preventIdleSleep, preventDiskSleep
        case preventSystemSleepOnAC, declareUserActive, waitForPID, utilityCommand
    }

    /// The options of the built-in default profile: keep display and system awake.
    public static let keepAwake = CaffeinateOptions(preventDisplaySleep: true, preventIdleSleep: true)

    private var trimmedCommand: String? {
        guard let command = utilityCommand?.trimmingCharacters(in: .whitespacesAndNewlines),
              !command.isEmpty else { return nil }
        return command
    }

    /// Whether a session timeout may be applied to these options. Waiting on
    /// a PID or running a utility command bounds the run by that process
    /// instead — a timeout must neither cut it short nor outlive it.
    public var supportsTimeout: Bool {
        waitForPID == nil && trimmedCommand == nil
    }

    /// Argument vector for `/usr/bin/caffeinate` (executable not included).
    /// `timeoutSeconds` is emitted as `-t` only when `supportsTimeout`.
    public func arguments(timeoutSeconds: Int? = nil) -> [String] {
        var args: [String] = []
        if preventDisplaySleep { args.append("-d") }
        if preventIdleSleep { args.append("-i") }
        if preventDiskSleep { args.append("-m") }
        if preventSystemSleepOnAC { args.append("-s") }
        if declareUserActive { args.append("-u") }
        if let timeout = timeoutSeconds, supportsTimeout { args += ["-t", String(timeout)] }
        if let pid = waitForPID { args += ["-w", String(pid)] }
        if let command = trimmedCommand { args += ["/bin/sh", "-c", command] }
        return args
    }
}
