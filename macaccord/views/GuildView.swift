//
//  ServerView.swift
//  macaccord
//
//  Created by đỗ quyên on 2/10/25.
//

import SwiftUI

struct GuildView: View {
    let guildId: String
    let size: CGFloat
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(
                url: discordWebSocket.guilds[guildId]?.iconURL,
                placeholder:
                    AnyView(
                    Image(systemName: "questionmark"))
                ,
                errorImage:
                    AnyView(
                    Image(systemName: "questionmark"))
            )
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
