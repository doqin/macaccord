//
//  DateFormatter.swift
//  macaccord
//
//  Created by đỗ quyên on 18/08/2025.
//

import Foundation

// MARK: - Custom Date Decoder
extension DateFormatter {
    static let discordISO8601WithMicroseconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let discordISO8601WithoutMicroseconds: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
    }()
}
