//
//  EnvironmentData.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI

class UserData : ObservableObject {
    @Published var users: [String: User] = [:]
}

class GuildData: ObservableObject {
    @Published var guilds: [Guild] = []
}
