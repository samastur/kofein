import Foundation

/// Lookup into the bundled string catalog (`Localizable.xcstrings`).
///
/// The system resolves the account's preferred language against the catalog's
/// localizations and falls back to English (the source language) when a
/// translation is missing.
public enum L10n {
    /// Language override chosen in the app ("en", "sl"); `nil` follows the
    /// account's system language. Set by the app at launch and when the user
    /// picks a language from the menu.
    nonisolated(unsafe) public static var languageOverride: String?

    /// Language codes the string tables ship for, e.g. ["en", "sl"].
    public static var supportedLanguages: [String] {
        Bundle.module.localizations.filter { $0 != "Base" }.sorted()
    }

    /// The language's name in itself ("English", "Slovenščina") — the usual
    /// way to label language pickers.
    public static func autonym(for code: String) -> String {
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forLanguageCode: code) ?? code
        return name.capitalized(with: locale)
    }

    public static func string(_ key: String) -> String {
        string(key, language: languageOverride)
    }

    /// Locale matching the current language choice — for formatters that
    /// should follow the in-app language override.
    public static var locale: Locale {
        locale(for: languageOverride)
    }

    public static func locale(for language: String?) -> Locale {
        language.map(Locale.init(identifier:)) ?? .autoupdatingCurrent
    }

    /// Looks the key up in the given language's table; with `nil` (or an
    /// unknown language) it defers to the system's language resolution,
    /// which falls back to English.
    public static func string(_ key: String, language: String?) -> String {
        if let language,
           let path = Bundle.module.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return Bundle.module.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Every key the app uses. Tests iterate this list to guarantee full
    /// translation coverage for each supported language.
    public static let allKeys: [String] = [
        "profile.keepAwake.name",
        "menu.status.active",
        "menu.status.inactive",
        "menu.profiles.header",
        "menu.manageProfiles",
        "menu.startAtLogin",
        "menu.language",
        "menu.language.system",
        "menu.timeout",
        "menu.timeout.indefinite",
        "menu.timeout.custom",
        "menu.timeout.customFormat",
        "menu.timeout.incompatible",
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
        "option.pid.label",
        "option.pid.help",
        "option.command.label",
        "option.command.help",
        "alert.startFailed.title",
        "alert.startFailed.message",
        "alert.saveFailed.title",
        "alert.loginItemFailed.title",
        "alert.customTimeout.title",
        "alert.customTimeout.message",
        "unit.minutes",
        "unit.hours",
        "common.ok",
        "common.cancel",
    ]
}
