//
//  GuildChannelListView.swift
//  macaccord
//
//  Created by đỗ quyên on 3/10/25.
//

import SwiftUI

struct GuildChannelListView: View {
    
    let guildSelection: Guild
    @Binding var channelSelection: Channel?
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    
    var body: some View {
        let channels = guildSelection.channels.sorted { $0.position! < $1.position! }
        return VStack {
            ScrollView {
                ForEach(channels.filter{ $0.parent_id == nil }) { channel in
                    if channel.type == ChannelType.GUILD_CATEGORY.rawValue {
                        CollapsibleView(header: {
                            Text(channel.name ?? "Unknown category")
                                .foregroundStyle(.gray)
                                .padding(2)
                        }, content: {
                            VStack(spacing: 2) {
                                ForEach(channels.filter{ $0.parent_id ?? "" == channel.id }) { channel2 in
                                    channelButtonView(channel: channel2)
                                }
                            }
                        })
                        .padding(.horizontal, 4)
                    } else {
                        channelButtonView(channel: channel)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    private func channelButtonView(channel: Channel) -> some View {
        CustomButton {
            if channel.type == ChannelType.GUILD_TEXT.rawValue {
                channelSelection = channel
            }
        } label: {
            ChannelView(channel: channel)
                .environmentObject(discordWebSocket)
                .padding(1)
                .padding(.vertical, 3)
        } background: { isHovered in
            if let channelSelection = channelSelection, channelSelection.id == channel.id {
                AnyView(buttonClickedView)
            } else if isHovered {
                AnyView(buttonHighlightView)
            } else {
                AnyView(buttonPlainView)
            }
        }
        .buttonStyle(.plain)
    }
    
    var buttonClickedView: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2))
    }
    
    var buttonHighlightView: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1))
    }
    
    var buttonPlainView: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.clear)
    }
}
