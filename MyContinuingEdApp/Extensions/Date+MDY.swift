//
//  Date+MDY.swift
//  MyContinuingEdApp
//
//  Created by GitHub Copilot on 10/22/25.
//

import Foundation

extension Date {
    /// Returns a string in M/D/YYYY format using calendar components (e.g. "10/22/2025").
    /// This is deterministic and respects the provided Calendar/timeZone.
    func mdyString(using calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: self)
        guard let year = comps.year, let month = comps.month, let day = comps.day else { return "" }
        return "\(month)/\(day)/\(year)"
    }

    /// Returns a string in M/D/YYYY format using a cached DateFormatter (faster when used repeatedly).
    /// By default it uses the current locale/time zone but you can pass a different Locale.
    func mdyStringUsingFormatter(locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        return Date._mdyFormatter(locale: locale, timeZone: timeZone).string(from: self)
    }

    // MARK: - Private cached formatter
    private static var _mdyFormatters: [String: DateFormatter] = [:]
    private static let _mdyFormattersLock = NSLock()

    private static func _mdyFormatter(locale: Locale, timeZone: TimeZone) -> DateFormatter {
        let key = "\(locale.identifier)|\(timeZone.identifier)"
        _mdyFormattersLock.lock()
        defer { _mdyFormattersLock.unlock() }
        if let existing = _mdyFormatters[key] {
            return existing
        }
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = timeZone
        // Use numeric month/day/year without leading zeros (M/d/yyyy)
        f.dateFormat = "M/d/yyyy"
        _mdyFormatters[key] = f
        return f
    }
}
