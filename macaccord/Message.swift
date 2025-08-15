//
//  Message.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI
import Combine
import Collections
import AVKit

@MainActor
class MessageViewModel: ObservableObject {
    @Published var messages: Deque<Message> = []
    @Published var isLoading = true // Maybe should be false
    @Published var errorMessage: String? = nil
    let decoder: JSONDecoder = MessageDecoder.createDecoder()
    
    func fetchMessages(channel: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "https://discord.com/api/v9/channels/\(channel)/messages?limit=50") else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(KeychainHelper.standard.read(service: "auth", account: "token"), forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                errorMessage = "Server error: \(httpResponse.statusCode)"
                return
            }
            
            let data_string = String(data: data, encoding: .utf8) ?? ""
            
            Log.general.info("\(data_string)")
            // Decode the json
            messages = try decoder.decode(Deque<Message>.self, from: data)
        } catch {
            errorMessage = "Failed to fetch: \(error)"
        }
    }
}

struct Attachment: Codable, Identifiable, Hashable {
    var id: String
    let filename: String
    let url: String
    // let proxy_url: String
    let content_type: String?
    let width: Int?
    let height: Int?
}

struct Message: Codable, Identifiable {
    var id: String
    var author: User
    let channel_id: String
    let content: String
    let attachments: [Attachment]
    let timestamp: Date
}

struct MediaPlayerView: View {
    let player: AVPlayer
    
    init?(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        self.player = AVPlayer(url: url)
    }
    
    var body: some View {
        VideoPlayer(player: player) // Works for audio too
            .frame(height: 360)
            .onDisappear {
                player.pause()
            }
    }
}

// MARK: - Attachment List View
struct AttachmentListView: View {
    let attachments: [Attachment]
    var body: some View {
        VStack(alignment: .leading) {
            ImageAttachmentGridView(attachments: attachments.filter{ $0.content_type?.hasPrefix("image/") == true })
            MediaAttachmentListView(attachments: attachments.filter{$0.content_type?.hasPrefix("audio/") == true || $0.content_type?.hasPrefix("video/") == true })
        }
    }
}

// MARK: - Media Attachment List View
struct MediaAttachmentListView: View {
    let attachments: [Attachment]
    
    var body: some View {
        VStack {
            ForEach(attachments) { attachment in
                if let mediaView = MediaPlayerView(urlString: attachment.url) {
                    mediaView
                } else {
                    ProgressView("Loading media...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Image Attachment Grid View
struct ImageAttachmentGridView: View {
    let attachments: [Attachment]

    var body: some View {
        if attachments.count == 1 {
            // Single attachment: keep aspect ratio, cap height
            AttachmentImageView(urlString: attachments[0].url)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400, maxHeight: 300, alignment: .leading) // Add explicit max constraints
                .clipped()
                .cornerRadius(6)
        } else if attachments.count == 2 {
            // Two side-by-side squares
            HStack(spacing: 4) {
                ForEach(attachments.prefix(2), id: \.self) { attachment in
                    AttachmentImageView(urlString: attachment.url)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: 150, maxHeight: 150) // Constrain individual images
                        .clipped()
                        .cornerRadius(6)
                }
            }
            .frame(maxWidth: 304) // 2 * 150 + spacing
        } else if attachments.count == 3 {
            // One large + two small
            HStack(spacing: 4) {
                AttachmentImageView(urlString: attachments[0].url)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200) // Fixed size for predictable layout
                    .clipped()
                    .cornerRadius(6)
                
                VStack(spacing: 4) {
                    AttachmentImageView(urlString: attachments[1].url)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 98, height: 98) // Fixed size
                        .clipped()
                        .cornerRadius(6)
                    AttachmentImageView(urlString: attachments[2].url)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 98, height: 98) // Fixed size
                        .clipped()
                        .cornerRadius(6)
                }
            }
            .frame(maxWidth: 302) // 200 + 98 + spacing
        } else if attachments.count >= 4 {
            // 2x2 grid, last one shows +N
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(150), spacing: 4), count: 2), spacing: 4) {
                ForEach(attachments.prefix(4).indices, id: \.self) { i in
                    ZStack {
                        AttachmentImageView(urlString: attachments[i].url)
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 150, height: 150) // Fixed size
                            .clipped()
                            .cornerRadius(6)
                        
                        if i == 3 && attachments.count > 4 {
                            Color.black.opacity(0.5)
                                .cornerRadius(6)
                            Text("+\(attachments.count - 4)")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(maxWidth: 304) // 2 * 150 + spacing
        }
    }
}

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

// MARK: - Text Field View
struct TextFieldView: View {
    @State private var message: String = ""
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    @Binding var isSending: Bool
    
    var decoder: JSONDecoder = MessageDecoder.createDecoder()
    
    let channelId: String
    
    var body: some View {
        HStack(spacing: 0) {
            // The attachment button
            Button {
                // Doesn't do anything yet
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .font(.largeTitle)
            }
            .padding(8)
            .buttonStyle(.plain)
            // The actual Text field
            HStack {
                TextField("Message", text: $message)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .onSubmit {
                        Task {
                            do {
                                isSending = true
                                defer { isSending = false }
                                let messageToSend = message
                                message = ""
                                Log.network.info("Sending message '\(messageToSend)' to channel '\(channelId)'...")
                                let sentMessage = try await sendMessage(message: messageToSend)
                                Log.network.info("Sent message '\(sentMessage.content)'!")
                                // viewModel.messages.count > 0 ? viewModel.messages.prepend(sentMessage) : viewModel.messages.append(sentMessage)
                            } catch {
                                errorMessage = error.localizedDescription
                                showErrorAlert = true
                            }
                        }
                    }
                    .alert("Error", isPresented: $showErrorAlert, actions: {
                        Button("OK", role: .cancel) {}
                    }, message: {
                        Text(errorMessage)
                    })
                // The Emote button
                Button {
                    // Doesn't do anything yet
                } label: {
                    Image(systemName: "face.smiling.inverse")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                .padding(8)
                .buttonStyle(.plain)
            }
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 999).stroke(style: StrokeStyle(lineWidth: 0.5)).fill(Color.gray))
            )
            // The send button
            Button {
                if !message.isEmpty {
                    Task {
                        do {
                            isSending = true
                            defer { isSending = false }
                            let messageToSend = message
                            message = ""
                            Log.network.info("Sending message '\(messageToSend)' to channel '\(channelId)'...")
                            let sentMessage = try await sendMessage(message: messageToSend)
                            Log.network.info("Sent message '\(sentMessage.content)'!")
                            // viewModel.messages.count > 0 ? viewModel.messages.prepend(sentMessage) : viewModel.messages.append(sentMessage)
                        } catch {
                            errorMessage = error.localizedDescription
                            showErrorAlert = true
                        }
                    }
                }
            } label: {
                if message.isEmpty {
                    Image(systemName: "paperplane.circle")
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                } else {
                    Image(systemName: "paperplane.circle.fill")
                        .foregroundColor(.blue)
                        .font(.largeTitle)
                }
            }
            .padding(8)
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 4)
    }
    
    func sendMessage(message: String) async throws -> Message {
        guard let url = URL(
            string: "https://discord.com/api/v9/channels/\(channelId)/messages"
        ) else {
            throw URLError(.badURL)
        }
        
        let parameters: [String: Any] = [
            "content": message,
            "flags": 0,
            "mobile_network_type": "unknown",
            "nonce": generateNonce(),
            "tts": false
        ]
        let jsonBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(KeychainHelper.standard.read(service: "auth", account: "token"), forHTTPHeaderField: "Authorization")
        request.httpBody = jsonBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                throw HTTPError.statusCode(httpResponse.statusCode)
            }
            
            let message = try decoder.decode(Message.self, from: data)
            return message
        } catch {
            throw error
        }
    }
    
    func generateNonce() -> String {
        let nonce = UInt64.random(in: 1_000_000_000_000_000_000...9_999_999_999_999_999_999)
        return String(nonce)
    }
}

// MARK: - Sending indicator
struct SendingIndicator: View {
    @Binding var isSending: Bool
    
    var body: some View {
        VStack {
            Spacer()
            if isSending {
                // Sending indicator
                HStack(spacing: 2) {
                    Text("Sending")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    ProgressView()
                        .frame(width: 20, height: 20)
                        .scaleEffect(0.5)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue)
                .cornerRadius(8)
                .padding(4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.bouncy(duration: 0.4), value: isSending)
    }
}

// MARK: - Channel Detail View
struct ChannelDetailView: View {
    @StateObject private var viewModel = MessageViewModel()
    
    @State private var isSending = false
    @State private var messageSubscription: AnyCancellable?
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    @EnvironmentObject var userData: UserData
    
    let channelId: String
    
    init(channelId: String) {
        self.channelId = channelId
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let error = viewModel.errorMessage {
                Text("Whoops! An error has occurred")
                ScrollView {
                    Text(error)
                        .foregroundColor(.red)
                        .textSelection(.enabled)
                }
            } else {
                ZStack {
                    // Message list view
                    MessageListView()
                        .environmentObject(viewModel)
                        .environmentObject(userData)
                    // Sending indicator
                    SendingIndicator(isSending: $isSending)
                }
                
                // Text field
               TextFieldView(isSending: $isSending, channelId: channelId)
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding(4)
        .onAppear {
            messageSubscription = discordWebSocket.messagesPublisher(for: channelId)
                .receive(on: DispatchQueue.main)
                .sink { [weak viewModel] message in
                    Log.general.info("Appending message '\(message.content)' to message list...")
                    viewModel?.messages.prepend(message)
                }
        }
        .onDisappear {
            messageSubscription?.cancel()
        }
        .task {
            await viewModel.fetchMessages(channel: channelId)
        }
    }
}

/*
 #Preview {
 // MessageView(message: Message(username: "đỗ quyên", content: "skibidi toilet"))
 
 MessageList()
 .environmentObject(Authorization())
 }
 */

struct AttachmentGrid_Previews: PreviewProvider {
    static var previews: some View {
        //ScrollView {
            LazyVStack(spacing: 1) {
                MessageView(message:
                                Message(id: "1",
                                        author: User(id: "1", username: "đỗ quyên"),
                                        channel_id: "123",
                                        content: "skibidi toilet",
                                        attachments: [
                                            Attachment(id: "4", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: "image/png", width: nil, height: nil),
                                            Attachment(id: "5", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: "image/png", width: nil, height: nil),
                                            Attachment(id: "6", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: "image/png", width: nil, height: nil)
                                        ],
                                        timestamp: Date()
                                       )
                ).environmentObject(UserData())
                MessageView(message:
                                Message(id: "2",
                                        author: User(id: "2", username: "balls toucher"),
                                        channel_id: "123",
                                        content: "boo boo boo",
                                        attachments: [
                                            Attachment(id: "4", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: "image/png", width: nil, height: nil),
                                            Attachment(id: "5", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: "image/png", width: nil, height: nil),
                                            Attachment(id: "6", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: "image/png", width: nil, height: nil)
                                        ],
                                        timestamp: Date()
                                       )
                ).environmentObject(UserData())
                
                /*
                 ImageAttachmentGridView(attachments: [
                 Attachment(id: "4", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: nil, width: nil, height: nil),
                 Attachment(id: "5", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: nil, width: nil, height: nil),
                 Attachment(id: "6", filename: "amogus.png", url: "https://picsum.photos/id/1018/600/900", content_type: nil, width: nil, height: nil)
                 ])
                 */
            }
        //}
        //.frame(width: 300, height: 400)
    }
}
