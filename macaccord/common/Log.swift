//
//  Log.swift
//  macaccord
//
//  Created by đỗ quyên on 17/08/2025.
//

import os

struct Log {
    static let general = Logger(subsystem: "com.example.macaccord", category: "general")
    static let network = Logger(subsystem: "com.example.macaccord", category: "network")
    static let ui = Logger(subsystem: "com.example.macaccord", category: "ui")
}
