import Foundation

/// Lookup into the bundled string catalog (`Localizable.xcstrings`).
///
/// The system resolves the account's preferred language against the catalog's
/// localizations and falls back to English (the source language) when a
/// translation is missing.
public enum L10n {
    public static func string(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Every key the app uses. Tests iterate this list to guarantee full
    /// translation coverage for each supported language.
    public static let allKeys: [String] = [
        "profile.keepAwake.name",
        "menu.profiles.header",
        "menu.manageProfiles",
        "menu.startAtLogin",
        "menu.quit",
        "profiles.window.title",
        "editor.name.label",
        "editor.newProfile.name",
        "editor.add",
        "editor.delete",
        "editor.setDefault",
        "editor.default.badge",
        "option.display.label",
        "option.display.help",
        "option.idle.label",
        "option.idle.help",
        "option.disk.label",
        "option.disk.help",
        "option.systemAC.label",
        "option.systemAC.help",
        "option.userActive.label",
        "option.userActive.help",
        "option.timeout.label",
        "option.timeout.help",
        "option.pid.label",
        "option.pid.help",
        "option.command.label",
        "option.command.help",
        "alert.startFailed.title",
        "alert.startFailed.message",
        "alert.saveFailed.title",
        "alert.loginItemFailed.title",
    ]
}
