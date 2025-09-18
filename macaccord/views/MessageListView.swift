//
//  MessageView.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//


// MARK: - Message View
struct MessageView: View {
    var message: Message
    
    @State private var isOnMessage = false
    @State private var isOnUsername = false
    @State private var isOnProfilePicture = false
    
    @EnvironmentObject var userData: UserData
    
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
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.subheadline)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true) // Allow text to wrap properly
                }
                
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
}

// MARK: - Message List View
struct MessageListView: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        VStack {
            // Message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                                .rotationEffect(.degrees(180))
                                .scaleEffect(x: -1.0, y: 1.0)
                                .environmentObject(userData)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    )
                                )
                                .scrollTargetLayout()
                        }
                    }
                }
                .rotationEffect(.degrees(180))
                .scaleEffect(x: -1.0, y: 1.0)
                //.scrollTargetBehavior(.viewAligned)
                // .defaultScrollAnchor(.bottom)
                .onChange(of: viewModel.messages.count) {
                    if let firstMessage = viewModel.messages.first {
                        withAnimation(.bouncy(duration: 0.3)) {
                            proxy.scrollTo(firstMessage.id, anchor: .top)
                        }
                    }
                }
                Spacer()
            }
            .animation(.bouncy(duration: 0.3), value: viewModel.messages.count)
        }
    }
}