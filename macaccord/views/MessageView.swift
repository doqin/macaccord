//
//  MessageView.swift
//  macaccord
//
//  Created by đỗ quyên on 23/9/25.
//

import Foundation
import SwiftUI
import AppKit

// MARK: - Message View
struct MessageView: View {
    var message: Message
    var content: [MessagePart]
    let emojiSize: CGFloat
    
    @State private var isOnMessage = false
    @State private var isOnUsername = false
    @State private var isOnProfilePicture = false
    
    @EnvironmentObject var userData: UserData
    
    init(message: Message) {
        self.message = message
        self.content = parseMessage(self.message.content)
        self.emojiSize = self.content.count <= 1 ? 40 : 24
    }
    
    let avatarSize: CGFloat = 40
    
    var body: some View {
        HStack(alignment: .top) {
            // Profile picture
            AvatarView(userId: message.author.id, size: avatarSize)
                .environmentObject(userData)
                .overlay(
                    Circle()
                        .stroke(
                            .blue,
                            style: StrokeStyle(lineWidth: isOnProfilePicture ? 2 : 0)
                        )
                )
                .onHover(perform: { hovering in
                    isOnProfilePicture = hovering
                })
            VStack(alignment: .leading) {
                HStack {
                    // The username
                    Text(message.author.displayName)
                        .font(.headline)
                        .underline(isOnUsername)
                        .onHover(perform: { hovering in
                            isOnUsername = hovering
                        })
                        .textSelection(.enabled)
                    // The timestamp
                    Text(MessageDecoder.formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .textSelection(.enabled)
                }
                // The message content
                messageContent
                
                // Attachments with constrained width
                if !message.attachments.isEmpty {
                    AttachmentListView(attachments: message.attachments)
                        .frame(maxWidth: .infinity, alignment: .leading) // Constrain to available width
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure the whole message aligns left
        .padding(4)
        .background(isOnMessage ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isOnMessage = hovering
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        if !message.content.isEmpty {
            HStack(spacing: 0) {
                ForEach(content.indices, id: \.self) { i in
                    switch content[i] {
                    case .text(let str):
                        Text(str)
                            .font(.subheadline)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true) // Allow text to wrap properly
                    case .emote(_, let id, let animated):
                        if animated {
                            // Animated emoji (GIF) -> use NSImageView via NSViewRepresentable
                            AnimatedCachedImage(
                                url: URL(string: "https://cdn.discordapp.com/emojis/\(id).gif"),
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
                                url: URL(string: "https://cdn.discordapp.com/emojis/\(id).webp"),
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
            }
        }
    }
}
