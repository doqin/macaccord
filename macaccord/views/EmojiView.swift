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
    let isPersistent: Bool
    
    var body: some View {
        if isPersistent {
            if emoji.animated {
                // Animated emoji (GIF) -> use NSImageView via NSViewRepresentable
                AnimatedCachedImage(
                    url: URL(string: "https://cdn.discordapp.com/emojis/\(emoji.id).gif"),
                    placeholder:
                        AnyView(placeholder),
                    errorImage:
                        AnyView(placeholder)
                )
                .aspectRatio(contentMode: .fit)
                .frame(width: emojiSize, height: emojiSize)
            } else {
                // Static emoji -> normal SwiftUI Image
                CachedAsyncImage(
                    url: URL(string: "https://cdn.discordapp.com/emojis/\(emoji.id).webp"),
                    placeholder:
                        AnyView(placeholder),
                    errorImage:
                        AnyView(placeholder)
                )
                .aspectRatio(contentMode: .fit)
                .frame(width: emojiSize, height: emojiSize)
            }
        } else {
            if emoji.animated {
                // Animated emoji (GIF) -> use NSImageView via NSViewRepresentable
                AnimatedCachedImage(
                    url: URL(string: "https://cdn.discordapp.com/emojis/\(emoji.id).gif?size=64"),
                    placeholder:
                        AnyView(placeholder),
                    errorImage:
                        AnyView(placeholder)
                )
                .aspectRatio(contentMode: .fit)
                .frame(width: emojiSize, height: emojiSize)
            } else {
                // Static emoji -> normal SwiftUI Image
                AsyncImage(url: URL(string: "https://cdn.discordapp.com/emojis/\(emoji.id).webp?size=64"),
                    content: { image in
                        image
                        .resizable()
                    }, placeholder: {
                        placeholder
                    }
                )
                .aspectRatio(contentMode: .fit)
                .frame(width: emojiSize, height: emojiSize)
            }
        }
    }
    
    @ViewBuilder
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.gray.opacity(0.1))
    }
}
