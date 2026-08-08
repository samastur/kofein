/// Adds/removes the app from the current user's login items.
public protocol LoginItemManaging {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}
