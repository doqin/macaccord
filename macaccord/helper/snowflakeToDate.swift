//
//  snowflakeToDate.swift
//  macaccord
//
//  Created by đỗ quyên on 16/9/25.
//

import Foundation

func snowflakeToDate(_ snowflake: UInt64) -> Date {
    let discordEpoch: UInt64 = 1_420_070_400_000 // 2015-01-01T00:00:00.000Z in ms
    let timestamp = (snowflake >> 22) + discordEpoch
    return Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
}
