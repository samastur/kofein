import AppKit
import KofeinCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var store: ProfileStore!
    private(set) var controller: CaffeinateController!
    private(set) var loginItems: LoginItemManaging = SMAppServiceLoginItemManager()
    private var statusItemController: StatusItemController!
    private var profilesWindowController: ProfilesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
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
            showProfiles: { [weak self] in self?.showProfilesWindow() }
        )
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
