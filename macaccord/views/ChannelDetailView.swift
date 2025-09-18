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
                    SendingIndicatorView(isSending: $isSending)
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
