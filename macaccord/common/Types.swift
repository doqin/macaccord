//
//  Types.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//

import Foundation

struct Attachment: Codable, Identifiable, Hashable {
    var id: String
    let filename: String
    let url: String
    // let proxy_url: String
    let content_type: String?
    let width: Int?
    let height: Int?
}

struct Message: Codable, Identifiable {
    var id: String
    var author: User
    let channel_id: String
    let content: String
    let attachments: [Attachment]
    let timestamp: Date
}

struct Channel: Hashable, Codable, Identifiable {
    var id: String
    var last_message_id: String?
    var last_message_timestamp: Date?
    var recipients: [User]
}

struct User: Hashable, Equatable, Codable, Identifiable {
    var id: String
    var username: String
    var global_name: String?
    var avatar: String?
    var status: String? = "offline"
    
    var avatarURL: URL? {
        guard let avatar = avatar else { return nil }
        
        let fileName: String
        if avatar.hasPrefix("a_") {
            fileName = "\(avatar).gif?size=64"
        } else {
            fileName = "\(avatar).webp?size=64"
        }
        
        return URL(string: "https://cdn.discordapp.com/avatars/\(id)/\(fileName)")
    }
    
    var displayName: String {
        return global_name ?? username
    }
}
