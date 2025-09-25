//
//  macaccordApp.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI
import SwiftData

@main
struct macaccordApp: App {
    
    @State private var me: User?
    @State private var isLoading: Bool = true
    
    @StateObject private var discordWebSocket: DiscordWebSocket = DiscordWebSocket()
    @StateObject private var userData = UserData()
    @StateObject private var channelViewModel: ChannelViewModel = ChannelViewModel()
    
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
            if isLoggedIn && isLoading == true {
                SetupView()
                    .task {
                        Log.network.info("Connecting discord websocket...")
                        discordWebSocket.connect()
                        Log.network.info("Fetching channels...")
                        await channelViewModel.fetchChannels()
                        for channel in channelViewModel.channels {
                            for recipient in channel.recipients {
                                if userData.users[recipient.id] == nil {
                                    userData.users[recipient.id] = recipient
                                }
                            }
                        }
                        while(true) {
                            do {
                                Log.network.info("Fetching my profile...")
                                me = try await fetchMe()
                                break
                            } catch (let e) {
                                Log.network.error("\(e.localizedDescription)")
                                Log.network.info("Retrying...")
                            }
                        }
                        // This should not fail
                        Log.network.info("Fetched my profile! \(me!.id)")
                        userData.users[me!.id] = me
                        Log.network.info("Setup complete!")
                        isLoading = false
                    }
            } else if isLoggedIn && isLoading == false {
                ContentView(myID: me!.id)
                    .environmentObject(userData)
                    .environmentObject(channelViewModel)
                    .environmentObject(discordWebSocket)
            } else {
                LoginView()
            }
        }
        .modelContainer(sharedModelContainer)
        
        Settings {
            SettingsView()
        }
    }
}
