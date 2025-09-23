//
//  DMList.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI



struct ChannelView: View {
    
    let channel: Channel
    let overlap: CGFloat = 16
    let avatarSize: CGFloat = 24
    
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        HStack(spacing: 2) {
            HStack(spacing: -overlap) {
                ForEach(channel.recipients) { recipient in
                    AvatarView(userId: recipient.id, size: avatarSize, isShowStatus: true)
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

struct DMListView: View {
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
                        ForEach(channels.sorted(by: { $0.last_message_timestamp ?? snowflakeToDate(1_420_070_400_000) > $1.last_message_timestamp ?? snowflakeToDate(1_420_070_400_000)})) { channel in
                            ChannelView(channel: channel)
                                .environmentObject(userData)
                                .tag(channel)
                        }
                    }
                }
                .searchable(text: $searchText, placement: .sidebar, prompt: "Search friends")
            }
        }
    }
}
