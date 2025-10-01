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
    
    @EnvironmentObject var guildData: GuildData
    
    private let emojiSize: CGFloat = 40
    
    private let gridItems: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 4), count: 9)
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .padding(8)
                TextField("Find the perfect emoji", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .background(
                backgroundView
            )
            ScrollView {
                LazyVStack {
                    if searchText.isEmpty {
                        ForEach(guildData.guilds) { guild in
                            CollapsibleView(header: {
                                Text(guild.name)
                            }, content: {
                                LazyVGrid(columns: gridItems) {
                                    ForEach(guild.emojis) { emoji in
                                        emojiButton(emoji: emoji)
                                    }
                                }
                            })

                                
                        }
                    } else {
                        let emojis = guildData.guilds.flatMap{ $0.emojis }.filter {$0.name.localizedCaseInsensitiveContains(searchText)}
                        LazyVGrid(columns: gridItems) {
                            ForEach(emojis) { emoji in
                                emojiButton(emoji: emoji)
                            }
                        }
                    }
                }
                
            }
        }
        .frame(width: 400)
        .padding(8)
        .background(backgroundView)
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
    private func emojiButton(emoji: Emoji) -> some View {
        Button{
            let emojiText = "<\(emoji.animated ? "a" : "" ):\(emoji.name):\(emoji.id)>"
            Task {
                textFieldMessage.append(emojiText)
            }
        } label: {
            EmojiView(emoji: emoji, emojiSize: emojiSize)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let guildData = GuildData()
    guildData.guilds.append(Guild(id: "1", name: "test", emojis: Array(repeating: Emoji(id: "1329394979298213989", name: "test", animated: false, available: true ), count: 11)))
    return EmojiPickerView(textFieldMessage: .constant(""))
        .environmentObject(guildData)
}
