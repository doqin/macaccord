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
    let isJustText: Bool
    
    @State private var isOnMessage = false
    @State private var isOnUsername = false
    @State private var isOnProfilePicture = false
    
    @EnvironmentObject var userData: UserData
    
    init(message: Message, isJustText: Bool) {
        self.message = message
        self.content = parseMessage(self.message.content)
        self.emojiSize = self.content.count <= 1 ? 40 : 24
        self.isJustText = isJustText
    }
    
    let avatarSize: CGFloat = 40
    
    var body: some View {
        HStack(alignment: .top) {
            // Profile picture
            if !isJustText {
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
            } else {
                Color.clear
                    .frame(width: avatarSize)
                    .padding(.horizontal, avatarSize/6)
            }
            VStack(alignment: .leading) {
                if !isJustText {
                    HStack {
                        // The username
                        Text(message.author.displayName)
                            .font(.title3)
                            .bold()
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
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure the whole message aligns left
        .padding(2)
        .background(isOnMessage ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isOnMessage = hovering
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        if !message.content.isEmpty {
            FlowLayout(spacing: 0) {
                ForEach(content.indices, id: \.self) { i in
                    switch content[i] {
                    case .text(let str):
                        Text(str)
                            .font(.title3)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true) // Allow text to wrap properly
                    case .emote(_, let id, let animated):
                        EmojiView(emoji: Emoji(id: id, name: "unavailable", animated: animated, available: true), emojiSize: emojiSize) // TODO: Maybe get the emoji name?
                    }
                }
            }
        }
    }
}
