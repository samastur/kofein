import Foundation

/// Session timeout choices offered in the menubar menu.
public enum TimeoutOption {
    /// 5, 10, 15, 30 minutes; 1, 2, 5 hours.
    public static let presetSeconds = [300, 600, 900, 1800, 3600, 7200, 18000]

    /// Human label for a duration ("5 minutes", "2 uri"). The formatter
    /// localizes unit names and plural forms (including Slovenian dual),
    /// so no catalog strings are needed for these.
    public static func label(seconds: Int, locale: Locale) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = seconds % 3600 == 0 ? [.hour] : [.minute]
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds) s"
    }
}
