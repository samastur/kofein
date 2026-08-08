import Foundation
import Testing
@testable import KofeinCore

@Test func everyKeyIsTranslatedInEnglishAndSlovenian() throws {
    for lang in ["en", "sl"] {
        let path = try #require(Bundle.module.path(forResource: lang, ofType: "lproj"),
                                "missing \(lang).lproj")
        let bundle = try #require(Bundle(path: path))
        for key in L10n.allKeys {
            let value = bundle.localizedString(forKey: key, value: "__MISSING__", table: nil)
            #expect(value != "__MISSING__" && !value.isEmpty, "\(lang): \(key)")
        }
    }
}

@Test func slovenianDiffersFromEnglishForQuit() throws {
    func value(_ lang: String) throws -> String {
        let path = try #require(Bundle.module.path(forResource: lang, ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        return bundle.localizedString(forKey: "menu.quit", value: nil, table: nil)
    }
    #expect(try value("en") != (try value("sl")))
}

@Test func l10nStringResolvesKnownKey() {
    #expect(L10n.string("menu.quit") != "menu.quit")
}

@Test func stringHonorsExplicitLanguage() {
    #expect(L10n.string("menu.quit", language: "en") == "Quit Kofein")
    #expect(L10n.string("menu.quit", language: "sl") == "Končaj Kofein")
}

@Test func unknownLanguageFallsBackToSystemLookup() {
    #expect(L10n.string("menu.quit", language: "de") != "menu.quit")
}

@Test func supportedLanguagesComeFromBundle() {
    #expect(L10n.supportedLanguages == ["en", "sl"])
}

@Test func autonymsAreNativeLanguageNames() {
    #expect(L10n.autonym(for: "en") == "English")
    #expect(L10n.autonym(for: "sl") == "Slovenščina")
}
