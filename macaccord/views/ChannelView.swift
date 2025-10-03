//
//  ChannelView.swift
//  macaccord
//
//  Created by đỗ quyên on 25/9/25.
//

import SwiftUI

struct ChannelView: View {
    
    let channel: Channel
    let overlap: CGFloat = 16
    let avatarSize: CGFloat = 32
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    
    var body: some View {
        HStack(spacing: 4) {
            switch channel.type {
            case ChannelType.DM.rawValue, ChannelType.GROUP_DM.rawValue:
                HStack(spacing: -overlap) {
                    ForEach(channel.recipients!) { recipient in
                        AvatarView(userId: recipient.id, size: avatarSize, isShowStatus: true)
                            .environmentObject(discordWebSocket)
                    }
                }
                Text(channel.recipients!.map(\.displayName).joined(separator: ", "))
                    .lineLimit(1)
                    .font(.title3)
                    .foregroundStyle(.gray)
            case ChannelType.GUILD_TEXT.rawValue:
                Group {
                    Image(systemName: "number")
                        .font(.title2)
                        .frame(width: 32)
                    Text(channel.name!)
                        .lineLimit(1)
                        .font(.title3)
                }
                .foregroundStyle(.gray)
            case ChannelType.GUILD_VOICE.rawValue:
                Group {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .frame(width: 32)
                    Text(channel.name!)
                        .lineLimit(1)
                        .font(.title3)
                }
                .foregroundStyle(.gray)
            case ChannelType.GUILD_ANNOUNCEMENT.rawValue:
                Group {
                    Image(systemName: "megaphone.fill")
                        .font(.title3)
                        .frame(width: 32)
                    Text(channel.name!)
                        .lineLimit(1)
                        .font(.title3)
                }
                .foregroundStyle(.gray)
            case ChannelType.GUILD_FORUM.rawValue:
                Group {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title3)
                        .frame(width: 32)
                    Text(channel.name!)
                        .lineLimit(1)
                        .font(.title3)
                }
                .foregroundStyle(.gray)
            case ChannelType.GUILD_STAGE_VOICE.rawValue:
                Group {
                    Image(systemName: "shareplay")
                        .font(.title2)
                        .frame(width: 32)
                    Text(channel.name!)
                        .lineLimit(1)
                        .font(.title3)
                }
                .foregroundStyle(.gray)
            default:
                Text(channel.name ?? "unknown")
                    .lineLimit(1)
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
