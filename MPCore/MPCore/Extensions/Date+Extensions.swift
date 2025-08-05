//
//  File.swift
//  MPCore
//
//  Created by mac on 04/08/2025.
//

import Foundation

public extension DateFormatter {
    /// ISO8601 date formatter for API responses (yyyy-MM-dd)
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
