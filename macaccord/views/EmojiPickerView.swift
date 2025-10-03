//
//  EmojiPickerView.swift
//  macaccord
//
//  Created by đỗ quyên on 1/10/25.
//

import SwiftUI

struct EmojiPickerView: View {
    
    @Binding var textFieldMessage: String
    @State private var searchText: String = ""
    @State private var guildSelection: Guild?
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    
    private let emojiSize: CGFloat = 40
    private let gridItems: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 4), count: 9)
    
    var body: some View {
        VStack(spacing: 0) {
            searchBarView
                .padding(8)
            HStack {
                GuildListView(selection: $guildSelection, iconSize: 30, showDMButton: false)
                    .environmentObject(discordWebSocket)
                    .padding(8)
                    .background(
                        .background
                    )
                ScrollView {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {
                        if searchText.isEmpty {
                            fullEmojiView
                        } else {
                            filteredEmojiView
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .frame(width: 450, height: 420)
        .background(backgroundView)
    }
    
    @ViewBuilder
    private var fullEmojiView: some View {
        ForEach(discordWebSocket.user_settings?.guild_folders.flatMap { $0.guild_ids } ?? [], id: \.self) { key in
            if let guild = discordWebSocket.guilds[key], !guild.emojis.isEmpty {
                Section {
                    LazyVGrid(columns: gridItems) {
                        ForEach(guild.emojis) { emoji in
                            emojiButtonView(emoji: emoji)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    HStack {
                        GuildView(guildId: guild.id, size: 16)
                            .environmentObject(discordWebSocket)
                        Text(guild.name)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .background(
                        Rectangle()
                            .fill(.background)
                            .overlay(
                                Rectangle()
                                    .fill(.gray.opacity(0.1))
                            )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var filteredEmojiView: some View {
        let emojis = discordWebSocket.guilds.values
            .flatMap { $0.emojis }
            .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        
        Section {
            LazyVGrid(columns: gridItems) {
                ForEach(emojis) { emoji in
                    emojiButtonView(emoji: emoji)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var searchBarView: some View {
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .padding(8)
            TextField("Find the perfect emoji", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .background(backgroundView)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .stroke(Color.gray, lineWidth: 0.5)
            )
    }
    
    @ViewBuilder
    private func emojiButtonView(emoji: Emoji) -> some View {
        Button {
            let emojiText = "<\(emoji.animated ? "a" : "" ):\(emoji.name):\(emoji.id)>"
            textFieldMessage.append(emojiText)
        } label: {
            EmojiView(emoji: emoji, emojiSize: emojiSize, isPersistent: false)
                .frame(width: emojiSize, height: emojiSize)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
