import AppKit
import KofeinCore

/// Owns the menubar item: left-click toggles caffeinate with the active
/// profile, right-click shows the menu.
@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let store: ProfileStore
    private let controller: CaffeinateController
    private let loginItems: LoginItemManaging
    private let showProfiles: () -> Void
    private let setLanguage: (String?) -> Void

    /// The profile the left-click toggle uses. Starts as the stored default;
    /// the right-click menu can switch it for this session.
    private var activeProfileID: UUID

    init(store: ProfileStore,
         controller: CaffeinateController,
         loginItems: LoginItemManaging,
         showProfiles: @escaping () -> Void,
         setLanguage: @escaping (String?) -> Void) {
        self.store = store
        self.controller = controller
        self.loginItems = loginItems
        self.showProfiles = showProfiles
        self.setLanguage = setLanguage
        self.activeProfileID = store.defaultProfileID
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        controller.onStateChange = { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.updateIcon() }
        }
        updateIcon()
    }

    private var activeProfile: Profile {
        store.profiles.first(where: { $0.id == activeProfileID }) ?? store.defaultProfile
    }

    private func updateIcon() {
        // Menubar cups from Caffeine (github.com/domzilla/Caffeine, MIT —
        // see THIRD-PARTY-LICENSES.md): full steaming cup when active,
        // empty cup when inactive.
        let name = controller.isActive ? "active" : "inactive"
        let image = Bundle.module.image(forResource: name)
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            toggle()
        }
    }

    private func toggle() {
        do {
            try controller.toggle(activeProfile)
        } catch {
            presentStartFailure(error)
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let statusKey = controller.isActive ? "menu.status.active" : "menu.status.inactive"
        let status = NSMenuItem(title: L10n.string(statusKey), action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let header = NSMenuItem(title: L10n.string("menu.profiles.header"), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        for profile in store.profiles {
            let item = NSMenuItem(title: profile.name,
                                  action: #selector(selectProfile(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = profile.id
            item.state = profile.id == activeProfileID ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let manage = NSMenuItem(title: L10n.string("menu.manageProfiles"),
                                action: #selector(manageProfiles),
                                keyEquivalent: "")
        manage.target = self
        menu.addItem(manage)

        let loginItem = NSMenuItem(title: L10n.string("menu.startAtLogin"),
                                   action: #selector(toggleLoginItem),
                                   keyEquivalent: "")
        loginItem.target = self
        loginItem.state = loginItems.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(languageMenuItem())

        menu.addItem(.separator())

        let quit = NSMenuItem(title: L10n.string("menu.quit"),
                              action: #selector(NSApplication.terminate(_:)),
                              keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)

        // Show the menu from a button action: attach it, synthesize a click,
        // then detach so the next left-click toggles instead of opening it.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func selectProfile(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID,
              let profile = store.profiles.first(where: { $0.id == id }) else { return }
        activeProfileID = profile.id
        if controller.isActive {
            do {
                try controller.activate(profile)
            } catch {
                presentStartFailure(error)
            }
        }
    }

    @objc private func manageProfiles() {
        showProfiles()
    }

    /// "Language" submenu: System Default plus every shipped language,
    /// labeled with its own name; checkmark on the current choice.
    private func languageMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: L10n.string("menu.language"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let system = NSMenuItem(title: L10n.string("menu.language.system"),
                                action: #selector(selectLanguage(_:)),
                                keyEquivalent: "")
        system.target = self
        system.state = L10n.languageOverride == nil ? .on : .off
        submenu.addItem(system)
        submenu.addItem(.separator())

        for code in L10n.supportedLanguages {
            let language = NSMenuItem(title: L10n.autonym(for: code),
                                      action: #selector(selectLanguage(_:)),
                                      keyEquivalent: "")
            language.target = self
            language.representedObject = code
            language.state = L10n.languageOverride == code ? .on : .off
            submenu.addItem(language)
        }

        item.submenu = submenu
        return item
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        setLanguage(sender.representedObject as? String)
    }

    @objc private func toggleLoginItem() {
        do {
            try loginItems.setEnabled(!loginItems.isEnabled)
        } catch {
            let alert = NSAlert()
            alert.messageText = L10n.string("alert.loginItemFailed.title")
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func presentStartFailure(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = L10n.string("alert.startFailed.title")
        alert.informativeText = L10n.string("alert.startFailed.message")
        alert.runModal()
    }
}
