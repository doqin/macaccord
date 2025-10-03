//
//  GuildListView.swift
//  macaccord
//
//  Created by đỗ quyên on 3/10/25.
//

import SwiftUI

struct GuildListView: View {
    
    @Binding var selection: Guild?
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    
    let iconSize: CGFloat
    
    let showDMButton: Bool
    
    var body: some View {
        ScrollView {
            VStack {
                if showDMButton {
                    Button {
                        selection = nil
                    } label: {
                        Image(systemName: "text.bubble.fill")
                            .font(.title3)
                            .frame(width: iconSize, height: iconSize)
                            .background(
                                backgroundView
                            )
                    }
                    .buttonStyle(.plain)
                }
                ForEach(discordWebSocket.user_settings!.guild_folders, id: \.self) { guildFolder in
                    if guildFolder.guild_ids.count == 1 {
                        Button {
                            selection = discordWebSocket.guilds[guildFolder.guild_ids.first!]
                        } label: {
                            GuildView(guildId: guildFolder.guild_ids.first!, size: iconSize)
                                .environmentObject(discordWebSocket)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(systemName: "folder")
                            .foregroundStyle(.gray)
                            .frame(width: iconSize, height: iconSize)
                            .background(backgroundView)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.1))
            )
    }
}
