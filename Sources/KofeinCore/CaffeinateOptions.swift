import Foundation

/// One combination of `/usr/bin/caffeinate` options.
///
/// Mirrors the full option surface of caffeinate(8): the five assertion
/// flags, `-t timeout`, `-w pid`, and the optional trailing utility command.
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
    /// `-t` — drop the assertions after this many seconds.
    public var timeoutSeconds: Int?
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
        timeoutSeconds: Int? = nil,
        waitForPID: Int32? = nil,
        utilityCommand: String? = nil
    ) {
        self.preventDisplaySleep = preventDisplaySleep
        self.preventIdleSleep = preventIdleSleep
        self.preventDiskSleep = preventDiskSleep
        self.preventSystemSleepOnAC = preventSystemSleepOnAC
        self.declareUserActive = declareUserActive
        self.timeoutSeconds = timeoutSeconds
        self.waitForPID = waitForPID
        self.utilityCommand = utilityCommand
    }

    /// The options of the built-in default profile: keep display and system awake.
    public static let keepAwake = CaffeinateOptions(preventDisplaySleep: true, preventIdleSleep: true)

    /// Argument vector for `/usr/bin/caffeinate` (executable not included).
    public var arguments: [String] {
        var args: [String] = []
        if preventDisplaySleep { args.append("-d") }
        if preventIdleSleep { args.append("-i") }
        if preventDiskSleep { args.append("-m") }
        if preventSystemSleepOnAC { args.append("-s") }
        if declareUserActive { args.append("-u") }
        if let timeout = timeoutSeconds { args += ["-t", String(timeout)] }
        if let pid = waitForPID { args += ["-w", String(pid)] }
        if let command = utilityCommand?.trimmingCharacters(in: .whitespacesAndNewlines),
           !command.isEmpty {
            args += ["/bin/sh", "-c", command]
        }
        return args
    }
}
