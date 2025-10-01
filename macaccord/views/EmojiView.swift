//
//  EmojiView.swift
//  macaccord
//
//  Created by đỗ quyên on 1/10/25.
//

import SwiftUI

struct EmojiView: View {
    
    let emoji: Emoji
    let emojiSize: CGFloat
    
    var body: some View {
        if emoji.animated {
            // Animated emoji (GIF) -> use NSImageView via NSViewRepresentable
            AnimatedCachedImage(
                url: URL(string: "https://cdn.discordapp.com/emojis/\(emoji.id).gif"),
                placeholder:
                    Image(systemName: "square.dashed")
                    .resizable(),
                errorImage:
                    Image(systemName: "questionmark.square.dashed")
                    .resizable()
            )
            .aspectRatio(contentMode: .fit)
            .frame(width: emojiSize, height: emojiSize)
        } else {
            // Static emoji -> normal SwiftUI Image
            CachedAsyncImage(
                url: URL(string: "https://cdn.discordapp.com/emojis/\(emoji.id).webp"),
                placeholder:
                    Image(systemName: "square.dashed")
                    .resizable()
                ,
                errorImage:
                    Image(systemName: "questionmark.square.dashed")
                    .resizable()
            )
            .aspectRatio(contentMode: .fit)
            .frame(width: emojiSize, height: emojiSize)
        }
    }
}
