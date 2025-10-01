//
//  DMList.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import SwiftUI

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
