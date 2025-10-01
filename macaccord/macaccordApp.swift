//
//  macaccordApp.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI
import SwiftData
import Combine

@main
struct macaccordApp: App {
    @State private var setupMessage: String = "Setting up Discord..."
    @State private var me: User?
    @State private var isLoading: Bool = true
    
    @StateObject private var discordWebSocket: DiscordWebSocket = DiscordWebSocket()
    @StateObject private var userData = UserData()
    @StateObject private var guildData = GuildData()
    @StateObject private var channelViewModel: ChannelViewModel = ChannelViewModel()
    
    @State private var userSubscription: AnyCancellable?
    @State private var meSubscription: AnyCancellable?
    @State private var guildSubscription: AnyCancellable?
    @State private var presenceUpdateSubscription: AnyCancellable?
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    init() {
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn && (isLoading || !discordWebSocket.ready ) {
                SetupView(setupMessage: $setupMessage)
                    .task {
                        Log.network.info("Setting up subscriptions...")
                        setupSubscription()
                        Log.network.info("Fetching channels...")
                        setupMessage = "Fetching channels..."
                        await channelViewModel.fetchChannels()
                        for channel in channelViewModel.channels {
                            for recipient in channel.recipients {
                                if userData.users[recipient.id] == nil {
                                    userData.users[recipient.id] = recipient
                                }
                            }
                        }
                        Log.network.info("Connecting discord websocket...")
                        setupMessage = "Connecting to discord websocket..."
                        discordWebSocket.connect()
                        isLoading = false
                    }
            } else if isLoggedIn && !isLoading && discordWebSocket.ready {
                ContentView(myID: me!.id)
                    .environmentObject(userData)
                    .environmentObject(guildData)
                    .environmentObject(channelViewModel)
                    .environmentObject(discordWebSocket)
            } else if !isLoggedIn {
                LoginView()
            }
        }
        .modelContainer(sharedModelContainer)
        Settings {
            SettingsView()
        }
    }
    
    // MARK: - Helper Methods
    private func setupSubscription() {
        userSubscription = discordWebSocket.usersPublisherFull()
            .receive(on: DispatchQueue.main)
            .sink { [userData] user in
                userData.users[user.id] = user
            }
        meSubscription = discordWebSocket.usersPublisher(for: "me")
            .receive(on: DispatchQueue.main)
            .sink { [meBinding = $me] user in
                meBinding.wrappedValue = user
            }
        guildSubscription = discordWebSocket.guildPublisherFull()
            .receive(on: DispatchQueue.main)
            .sink { [guildData] guild in
                guildData.guilds.append(guild)
            }
        presenceUpdateSubscription = discordWebSocket.presenceUpdatePublisherFull()
            .receive(on: DispatchQueue.main)
            .sink { [userData] presenceUpdate in
                Log.general.info("Updating presence for \(presenceUpdate.user.id): \(presenceUpdate.status)")
                userData.users[presenceUpdate.user.id]?.status = presenceUpdate.status
            }
    }
}
