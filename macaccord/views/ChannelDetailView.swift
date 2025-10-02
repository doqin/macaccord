//
//  Message.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI
import Combine
import AVKit



// MARK: - Channel Detail View
struct ChannelDetailView: View {
    @StateObject private var viewModel = MessageViewModel()
    
    let duration: TimeInterval = 30
    
    @State private var isSending = false
    @State private var isTyping = false
    @State private var typingStartInfo: TypingStart?
    @State private var timer: Timer? = nil
    @State private var isOpeningPicker = false
    @State private var textFieldMessage = ""
    @State private var fileURLs: [URL] = []
    
    @State private var messageSubscription: AnyCancellable?
    @State private var typingStartSubscription: AnyCancellable?
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var guildData: GuildData
    
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
                    MessageListView(channelId: channelId)
                        .environmentObject(viewModel)
                        .environmentObject(userData)
                    // Sending indicator
                    VStack(spacing: 4) {
                        SendingIndicatorView(isSending: $isSending)
                        TypingView(isTyping: $isTyping, typingStartInfo: $typingStartInfo)
                    }
                    if isOpeningPicker {
                        HStack {
                            Spacer()
                            EmojiPickerView(textFieldMessage: $textFieldMessage)
                                .padding(8)
                                .environmentObject(guildData)
                        }
                    }
                }
                VStack {
                    // Imported attachments preview (only when there are selected files)
                    if !fileURLs.isEmpty {
                        ImportedAttachmentsView(fileURLs: $fileURLs)
                            .frame(height: 96)
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                    }
                    // Text field
                    TextFieldView(textFieldMessage: $textFieldMessage, isSending: $isSending, isOpeningPicker: $isOpeningPicker, fileURLs: $fileURLs, channelId: channelId)
                }
                .background(
                    backgroundView
                )
                .padding(4)
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding(4)
        .onAppear {
            messageSubscription = discordWebSocket.messagesPublisher(for: channelId)
                .receive(on: DispatchQueue.main)
                .sink { [weak viewModel] message in
                    isTyping = false
                    timer = nil
                    Log.general.info("Appending message '\(message.content)' to message list...")
                    viewModel?.messages.prepend(message)
                }
            typingStartSubscription = discordWebSocket.typingStartPublisher(for: channelId)
                .receive(on: DispatchQueue.main)
                .sink { typingStart in
                    typingStartInfo = typingStart
                    isTyping = true
                    timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                        isTyping = false
                        timer = nil
                    }
                }
        }
        .onDisappear {
            messageSubscription?.cancel()
        }
        .task {
            await viewModel.fetchMessages(channel: channelId)
        }
    }
    
    @ViewBuilder
    var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(style: StrokeStyle(lineWidth: 0.5)).fill(Color.gray))
    }
}
