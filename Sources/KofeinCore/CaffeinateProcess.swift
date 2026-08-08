import Foundation

/// Real `/usr/bin/caffeinate` child process.
///
/// `@unchecked Sendable`: `onTermination` is set from the main thread and read
/// only inside the main-queue hop below, so there is no concurrent access.
public final class CaffeinateProcess: ProcessRunning, @unchecked Sendable {
    public var onTermination: (() -> Void)?
    private let process = Process()

    public init() {}

    public func start(arguments: [String]) throws {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = arguments
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.onTermination?() }
        }
        try process.run()
    }

    public func terminate() {
        if process.isRunning {
            process.terminate()
        }
    }
}
