import AppKit
import KofeinCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var store: ProfileStore!
    private(set) var controller: CaffeinateController!
    private(set) var loginItems: LoginItemManaging = SMAppServiceLoginItemManager()
    private var statusItemController: StatusItemController!
    private var profilesWindowController: ProfilesWindowController?

    private static let languageDefaultsKey = "languageOverride"

    func applicationDidFinishLaunching(_ notification: Notification) {
        L10n.languageOverride = UserDefaults.standard.string(forKey: Self.languageDefaultsKey)
        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        store = ProfileStore(
            fileURL: supportDirectory.appendingPathComponent("Kofein/profiles.json"),
            seedProfileName: L10n.string("profile.keepAwake.name")
        )
        controller = CaffeinateController { CaffeinateProcess() }
        statusItemController = StatusItemController(
            store: store,
            controller: controller,
            loginItems: loginItems,
            showProfiles: { [weak self] in self?.showProfilesWindow() },
            setLanguage: { [weak self] code in self?.setLanguage(code) }
        )
    }

    /// Applies a language override (nil = follow the system language) and
    /// persists it. The menu is rebuilt on every click; the profiles window
    /// is discarded so it reopens in the new language.
    func setLanguage(_ code: String?) {
        L10n.languageOverride = code
        if let code {
            UserDefaults.standard.set(code, forKey: Self.languageDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.languageDefaultsKey)
        }
        profilesWindowController?.close()
        profilesWindowController = nil
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.deactivate()
    }

    func showProfilesWindow() {
        if profilesWindowController == nil {
            profilesWindowController = ProfilesWindowController(store: store)
        }
        profilesWindowController?.show()
    }
}
