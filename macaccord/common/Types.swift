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

struct Guild: Hashable, Codable, Identifiable {
    var id: String
    var name: String
    var icon: String?
    var channels: [Channel]
    var emojis: [Emoji]
    // var stickers: [Sticker]
    
    var iconURL: URL? {
        guard let icon = icon else { return nil }
        
        let fileName = "\(icon).png?size=80&quality=lossless"
        return URL(string: "https://cdn.discordapp.com/icons/\(id)/\(fileName)")
    }
}

struct Channel: Hashable, Codable, Identifiable {
    var id: String
    var position: Int?
    var type: Int
    var name: String?
    var parent_id: String?
    var last_message_id: String?
    var last_message_timestamp: Date?
    var recipients: [User]?
}

struct Emoji: Hashable, Codable, Identifiable {
    var id: String
    var name: String
    var animated: Bool
    var available: Bool
    // var require_colons: Bool (not sure what this is)
}

enum MessagePart: Identifiable {
    case text(String)
    case emote(name: String, id: String, animated: Bool)
    
    var id: UUID { UUID() }
}

enum ChannelType: Int {
    case GUILD_TEXT = 0
    case DM = 1
    case GUILD_VOICE = 2
    case GROUP_DM = 3
    case GUILD_CATEGORY = 4
    case GUILD_ANNOUNCEMENT = 5
    case ANNOUNCEMENT_THREAD = 10
    case PUBLIC_THREAD = 11
    case PRIVATE_THREAD = 12
    case GUILD_STAGE_VOICE = 13
    case GUILD_DIRECTORY = 14
    case GUILD_FORUM = 15
    case GUILD_MEDIA = 16 // Still in development
}
