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

    /// Session timeout for caffeinate runs; nil = run indefinitely.
    /// Chosen in the Timeout submenu, reset on relaunch.
    private var timeoutSeconds: Int?

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
            try controller.toggle(activeProfile, timeoutSeconds: timeoutSeconds)
        } catch {
            presentStartFailure(error)
        }
    }

    private func restartIfActive() {
        guard controller.isActive else { return }
        do {
            try controller.activate(activeProfile, timeoutSeconds: timeoutSeconds)
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

        addTimeoutItems(to: menu)

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
              store.profiles.contains(where: { $0.id == id }) else { return }
        activeProfileID = id
        restartIfActive()
    }

    /// "Timeout" submenu bounding how long the selected profile runs. For
    /// profiles that wait on a PID or run a command the item is disabled,
    /// with a notice explaining why.
    private func addTimeoutItems(to menu: NSMenu) {
        let item = NSMenuItem(title: L10n.string("menu.timeout"), action: nil, keyEquivalent: "")

        guard activeProfile.options.supportsTimeout else {
            item.isEnabled = false
            menu.addItem(item)
            let notice = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            notice.attributedTitle = NSAttributedString(
                string: L10n.string("menu.timeout.incompatible"),
                attributes: [
                    .font: NSFont.menuFont(ofSize: NSFont.smallSystemFontSize),
                    .foregroundColor: NSColor.secondaryLabelColor,
                ]
            )
            notice.isEnabled = false
            menu.addItem(notice)
            return
        }

        let submenu = NSMenu()

        let indefinite = NSMenuItem(title: L10n.string("menu.timeout.indefinite"),
                                    action: #selector(selectTimeout(_:)),
                                    keyEquivalent: "")
        indefinite.target = self
        indefinite.state = timeoutSeconds == nil ? .on : .off
        submenu.addItem(indefinite)
        submenu.addItem(.separator())

        for seconds in TimeoutOption.presetSeconds {
            let preset = NSMenuItem(title: TimeoutOption.label(seconds: seconds, locale: L10n.locale),
                                    action: #selector(selectTimeout(_:)),
                                    keyEquivalent: "")
            preset.target = self
            preset.representedObject = seconds
            preset.state = timeoutSeconds == seconds ? .on : .off
            submenu.addItem(preset)
        }
        submenu.addItem(.separator())

        let isCustom = timeoutSeconds.map { !TimeoutOption.presetSeconds.contains($0) } ?? false
        let customTitle: String = if isCustom, let seconds = timeoutSeconds {
            String(format: L10n.string("menu.timeout.customFormat"),
                   TimeoutOption.label(seconds: seconds, locale: L10n.locale))
        } else {
            L10n.string("menu.timeout.custom")
        }
        let custom = NSMenuItem(title: customTitle,
                                action: #selector(pickCustomTimeout),
                                keyEquivalent: "")
        custom.target = self
        custom.state = isCustom ? .on : .off
        submenu.addItem(custom)

        item.submenu = submenu
        menu.addItem(item)
    }

    @objc private func selectTimeout(_ sender: NSMenuItem) {
        timeoutSeconds = sender.representedObject as? Int
        restartIfActive()
    }

    @objc private func pickCustomTimeout() {
        let alert = NSAlert()
        alert.messageText = L10n.string("alert.customTimeout.title")
        alert.informativeText = L10n.string("alert.customTimeout.message")
        alert.addButton(withTitle: L10n.string("common.ok"))
        alert.addButton(withTitle: L10n.string("common.cancel"))

        let field = NSTextField(string: "")
        let numbers = NumberFormatter()
        numbers.minimum = 1
        numbers.maximumFractionDigits = 0
        field.formatter = numbers
        field.widthAnchor.constraint(equalToConstant: 100).isActive = true
        let units = NSPopUpButton(frame: .zero, pullsDown: false)
        units.addItems(withTitles: [L10n.string("unit.minutes"), L10n.string("unit.hours")])
        let stack = NSStackView(views: [field, units])
        stack.orientation = .horizontal
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        stack.setFrameSize(stack.fittingSize)
        alert.accessoryView = stack
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let value = field.integerValue
        guard value > 0 else {
            NSSound.beep()
            return
        }
        timeoutSeconds = value * (units.indexOfSelectedItem == 0 ? 60 : 3600)
        restartIfActive()
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
