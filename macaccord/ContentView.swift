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
    
    @State private var showInspector = false
    @State private var selection = 1
    @State private var channelSelection: Channel?
    @State private var presenceUpdateSubscription: AnyCancellable?
    @State private var userSubscription: AnyCancellable?
    
    @StateObject private var discordWebSocket: DiscordWebSocket = DiscordWebSocket()
    @StateObject private var userData = UserData()
    @StateObject private var channelViewModel: ChannelViewModel = ChannelViewModel()
    
    
    let overlap: CGFloat = 16
    let avatarSize: CGFloat = 32
    
    // MARK: - Body
    var body: some View {
        NavigationSplitView {
            // Left sidebar
            sidebarContent
        } detail: {
            detailContent
        }
        .navigationSplitViewColumnWidth(min: 500, ideal: 500)
        .inspector(isPresented: $showInspector) {
            inspectorContent
        }
        .task {
            setupWebSocket()
            await channelViewModel.fetchChannels()
            for channel in channelViewModel.channels {
                for recipient in channel.recipients {
                    if userData.users[recipient.id] == nil {
                        userData.users[recipient.id] = recipient
                    }
                }
            }
        }
    }
    
    // MARK: - Sidebar
    @ViewBuilder
    private var sidebarContent: some View {
        VStack {
            sidebarPicker
            sidebarList
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
        .padding(4)
    }
    
    @ViewBuilder
    private var sidebarList: some View {
        switch selection {
        case 0:
            List {
                
            }
        case 1:
            DMList(selection: $channelSelection)
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
            ChannelDetailView(channelId: channelSelection.id)
                .id(channelSelection.id)
                .environmentObject(discordWebSocket)
                .environmentObject(userData)
                .navigationTitle(channelTitle)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        avatarStack
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
            .toolbar {
                Button(action: {
                    showInspector.toggle()
                }, label: {
                    Label("Toggle Inspector", systemImage: "sidebar.right")
                })
            }
    }
    
    // MARK: - Computed Properties
    private var channelTitle: String {
        channelSelection?.recipients.map { $0.global_name ?? $0.username }.joined(separator: ", ") ?? ""
    }
    
    // MARK: - Helper Methods
    private func setupWebSocket() {
        discordWebSocket.connect()
        userSubscription = discordWebSocket.usersPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak userData] user in
                userData?.users[user.id] = user
            }
        presenceUpdateSubscription = discordWebSocket.presenceUpdatePublisherFull()
            .receive(on: DispatchQueue.main)
            .sink { [weak userData] presenceUpdate in
                Log.general.info("Updating presence for \(presenceUpdate.user.id): \(presenceUpdate.status)")
                userData?.users[presenceUpdate.user.id]?.status = presenceUpdate.status
            }
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
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
