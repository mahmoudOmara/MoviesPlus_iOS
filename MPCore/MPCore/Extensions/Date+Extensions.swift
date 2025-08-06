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

public extension Date {
    /// A private shared formatter for extracting the year component from a `Date`.
    private static let yearOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// A private shared medium style date formatter
    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    /// Formats date to "yyyy" (year only)
    var yearString: String {
        return Self.yearOnlyFormatter.string(from: self)
    }
    
    /// Formats date to medium formate
    var mediumStrig: String {
        return Self.mediumDateFormatter.string(from: self)
    }
}
