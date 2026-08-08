import Foundation

/// A user-named combination of caffeinate options.
public struct Profile: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var options: CaffeinateOptions

    public init(id: UUID = UUID(), name: String, options: CaffeinateOptions) {
        self.id = id
        self.name = name
        self.options = options
    }
}
