import Foundation
import Testing
@testable import KofeinCore

@Test func presetsMatchTheSpecifiedDurations() {
    #expect(TimeoutOption.presetSeconds == [300, 600, 900, 1800, 3600, 7200, 18000])
}

@Test func englishLabelsUseFullUnitNames() {
    let en = Locale(identifier: "en")
    #expect(TimeoutOption.label(seconds: 300, locale: en) == "5 minutes")
    #expect(TimeoutOption.label(seconds: 3600, locale: en) == "1 hour")
    #expect(TimeoutOption.label(seconds: 18000, locale: en) == "5 hours")
}

@Test func slovenianLabelsUseCorrectPluralForms() {
    let sl = Locale(identifier: "sl")
    #expect(TimeoutOption.label(seconds: 300, locale: sl) == "5 minut")
    #expect(TimeoutOption.label(seconds: 3600, locale: sl) == "1 ura")
    #expect(TimeoutOption.label(seconds: 7200, locale: sl) == "2 uri") // dual!
}

@Test func nonWholeHoursAreLabeledInMinutes() {
    let en = Locale(identifier: "en")
    #expect(TimeoutOption.label(seconds: 2700, locale: en) == "45 minutes")
}

@Test func l10nLocaleFollowsLanguageParameter() {
    #expect(L10n.locale(for: "sl").identifier.hasPrefix("sl"))
    #expect(L10n.locale(for: nil) == Locale.autoupdatingCurrent)
}
