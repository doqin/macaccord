//
//  ContentView.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var isKeyWindow = true
    @State private var isMiniaturized = false
    
    @State private var showInspector = false
    @State private var selection = 1
    @State private var channelSelection: Channel?
    
    let myID: String
    @EnvironmentObject private var userData: UserData
    @EnvironmentObject private var guildData: GuildData
    @EnvironmentObject private var channelViewModel: ChannelViewModel
    @EnvironmentObject private var discordWebSocket: DiscordWebSocket
    
    @State private var messageSubscription: AnyCancellable?
    
    let overlap: CGFloat = 16
    let avatarSize: CGFloat = 32
    
    // MARK: - Body
    var body: some View {
        NavigationSplitView {
            // Left sidebar
            HStack(spacing: 0) {
                sidebarContent
            }
        } detail: {
            detailContent
        }
        .navigationSplitViewColumnWidth(min: 600, ideal: 600)
        .background(WindowStateObserver(isKeyWindow: $isKeyWindow, isMiniaturized: $isMiniaturized))
        .task {
            messageSubscription = discordWebSocket.messagesPublisherFull()
                .receive(on: DispatchQueue.main)
                .sink { [channelViewModel] message in
                    for idx in channelViewModel.channels.indices {
                        if channelViewModel.channels[idx].id == message.channel_id {
                            Log.general.info("Updating last message for \(message.channel_id): \(message.id)")
                            channelViewModel.channels[idx].last_message_timestamp = message.timestamp
                            if (channelSelection?.id != message.channel_id || isMiniaturized || !isKeyWindow) && message.author.id != myID {
                                sendNotification(title: message.author.displayName, body: message.content)
                            }
                        }
                    }
                    
                }
        }
    }
    
    // MARK: - Sidebar
    @ViewBuilder
    private var sidebarContent: some View {
        VStack {
            sidebarList
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        sidebarPicker
                    }
                }
            HStack {
                ChannelView(channel: Channel(id: "dummy_id", recipients: [userData.users[myID]!]))
                    .environmentObject(userData)
                Spacer()
                Image(systemName: "gear")
                    .font(.title)
                    .foregroundStyle(.gray)
            }
            .padding(8)
            .background(.gray.opacity(0.1))
            .cornerRadius(16)
        }
        .padding(4)
    }
    
    @ViewBuilder
    private var sidebarPicker: some View {
        Picker(selection: $selection) {
            Image(systemName: "server.rack").tag(0)
            Image(systemName: "text.bubble.fill").tag(1)
        } label: {}
            .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    private var sidebarList: some View {
        switch selection {
        case 0:
            List {
                
            }
        case 1:
            DMListView(selection: $channelSelection)
                .environmentObject(discordWebSocket)
                .environmentObject(channelViewModel)
                .environmentObject(userData)
        default:
            Text("How'd you get here?")
        }
    }
    
    // MARK: - Detail Content
    @ViewBuilder
    private var detailContent: some View {
        if let channelSelection {
            HSplitView {
                ChannelDetailView(channelId: channelSelection.id)
                    .id(channelSelection.id)
                    .environmentObject(discordWebSocket)
                    .environmentObject(userData)
                    .environmentObject(guildData)
                    .navigationTitle(channelTitle)
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            avatarStack
                        }
                    }
            }
        } else {
            Text("Select an item")
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private var avatarStack: some View {
        HStack(spacing: -overlap) {
            ForEach(channelSelection?.recipients ?? []) { recipient in
                AvatarView(userId: recipient.id, size: avatarSize, isShowStatus: true)
                    .environmentObject(discordWebSocket)
                    .environmentObject(userData)
            }
        }
    }
    
    @ViewBuilder
    private var inspectorContent: some View {
        Text("Placeholder")
    }
    
    // MARK: - Computed Properties
    private var channelTitle: String {
        channelSelection?.recipients.map { $0.global_name ?? $0.username }.joined(separator: ", ") ?? ""
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    //ContentView()
        //.modelContainer(for: Item.self, inMemory: true)
}
