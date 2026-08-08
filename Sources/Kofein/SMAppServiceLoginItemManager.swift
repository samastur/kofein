import KofeinCore
import ServiceManagement

/// Registers the app itself as a login item for the current user.
/// Requires the app to run from a real bundle (`Kofein.app`).
final class SMAppServiceLoginItemManager: LoginItemManaging {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
