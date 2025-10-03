//
//  GuildListView.swift
//  macaccord
//
//  Created by đỗ quyên on 2/10/25.
//

import SwiftUI

struct SidebarView: View {
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    @EnvironmentObject var channelViewModel: ChannelViewModel

    @Binding var guildSelection: Guild?
    @Binding var channelSelection: Channel?
    
    var body: some View {
        HSplitView {
            GuildListView(selection: $guildSelection, iconSize: 40, showDMButton: true)
                .environmentObject(discordWebSocket)
                .padding(8)
            Group {
                if let guildSelection = guildSelection {
                    GuildChannelListView(guildSelection: guildSelection, channelSelection: $channelSelection)
                        .environmentObject(discordWebSocket)
                        .padding(4)
                } else {
                    DMListView(selection: $channelSelection)
                        .environmentObject(discordWebSocket)
                        .environmentObject(channelViewModel)
                        .padding(8)
                }
            }
        }
    }
}

#Preview {
    /*
    let discordWebSocket = discordWebSocket()
    discordWebSocket.guilds["522681957373575168"] = Guild(
        id: "522681957373575168",
        name: "test",
        icon: "881c3d841d1cb5256d2be722f1ce7080",
        channels: [],
        emojis: []
    )
    return GuildListView(
        guildSelection: .constant(nil),
        channelSelection: .constant(nil)
    )
    .environmentObject(discordWebSocket)
     */
}

