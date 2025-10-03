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
    @State private var isLoading: Bool = true
    
    @StateObject private var discordWebSocket: DiscordWebSocket = DiscordWebSocket()
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
                        Log.network.info("Connecting discord websocket...")
                        setupMessage = "Connecting to discord websocket..."
                        discordWebSocket.connect()
                        Log.network.info("Fetching channels...")
                        setupMessage = "Fetching channels..."
                        await channelViewModel.fetchChannels()
                        for channel in channelViewModel.channels {
                            for recipient in channel.recipients! {
                                if discordWebSocket.users[recipient.id] == nil {
                                    discordWebSocket.users[recipient.id] = recipient
                                }
                            }
                        }
                        
                        isLoading = false
                    }
            } else if isLoggedIn && !isLoading && discordWebSocket.ready {
                ContentView()
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
}
