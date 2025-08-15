//
//  DMList.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI

@MainActor
class ChannelViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var isLoading = true // Maybe switch to false later
    @Published var errorMessage: String? = nil
    
    private var decoder: JSONDecoder = MessageDecoder.createDecoder()
    
    func fetchChannels() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "https://discord.com/api/v9/users/@me/channels?limit=50") else {
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
            
            // Decode the json
            channels = try decoder.decode([Channel].self, from: data)
        } catch {
            errorMessage = "Failed to fetch: \(error.localizedDescription)"
        }
    }
}

struct Channel: Hashable, Codable, Identifiable {
    var id: String
    var recipients: [User]
}

struct User: Hashable, Equatable, Codable, Identifiable {
    var id: String
    var username: String
    var global_name: String?
    var avatar: String?
    var status: String? = "offline"
    
    var avatarURL: URL? {
        guard let avatar = avatar else { return nil }
        
        let fileName: String
        if avatar.hasPrefix("a_") {
            fileName = "\(avatar).gif?size=64"
        } else {
            fileName = "\(avatar).webp?size=64"
        }
        
        return URL(string: "https://cdn.discordapp.com/avatars/\(id)/\(fileName)")
    }
    
    var displayName: String {
        return global_name ?? username
    }
}

struct ChannelView: View {
    
    let channel: Channel
    let overlap: CGFloat = 16
    let avatarSize: CGFloat = 24
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        HStack(spacing: 2) {
            HStack(spacing: -overlap) {
                ForEach(channel.recipients) { recipient in
                    AvatarView(userId: recipient.id, size: avatarSize, isShowStatus: true)
                        .environmentObject(discordWebSocket)
                        .environmentObject(userData)
                }
            }
                        
            Text(channel.recipients.map(\.displayName).joined(separator: ", "))
                .lineLimit(1)
                        
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct DMList: View {
    @EnvironmentObject private var viewModel: ChannelViewModel
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    @EnvironmentObject var userData: UserData
    
    @Binding var selection: Channel?
    
    @State private var searchText = ""
    
    private var channels: [Channel] {
        if searchText.isEmpty {
            return viewModel.channels
        } else {
            return viewModel.channels.filter { $0.recipients.map {$0.global_name ?? $0.username }.joined(separator: ", ") .localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading")
                Spacer()
            } else if let error = viewModel.errorMessage {
                Text("Whoops, got an error")
                ScrollView {
                    Text(error)
                        .foregroundColor(.red)
                }
            } else {
                List(selection: $selection) {
                    NavigationLink {
                        Text("WIP")
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.gray)
                                .padding(4)
                            Text("Friends")
                            Spacer()
                        }
                    }

                    Section("Direct Messages") {
                        ForEach(channels) { channel in
                            ChannelView(channel: channel)
                                .environmentObject(discordWebSocket)
                                .environmentObject(userData)
                                .tag(channel)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search friends")
            }
        }
    }
}
