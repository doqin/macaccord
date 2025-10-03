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
    
    @Binding var selection: Channel?
    
    @State private var searchText = ""
    
    private var channels: [Channel] {
        if searchText.isEmpty {
            return viewModel.channels
        } else {
            return viewModel.channels.filter { $0.recipients!.map {$0.global_name ?? $0.username }.joined(separator: ", ") .localizedCaseInsensitiveContains(searchText) }
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
                VStack(spacing: 2) {
                    ScrollView {
                        searchBarView
                        HStack {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.gray)
                                .padding(4)
                            Text("Friends")
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                        .padding(4)
                        Section {
                            let channels = channels.sorted(
                                by: {
                                    $0.last_message_timestamp
                                    ?? snowflakeToDate(1_420_070_400_000) > $1.last_message_timestamp
                                    ?? snowflakeToDate(1_420_070_400_000)
                                }
                            )
                            VStack(spacing: 2) {
                                if !searchText.isEmpty {
                                    let channels = channels.filter {
                                        $0.recipients!.contains(where: { $0.displayName.localizedCaseInsensitiveContains(searchText) })
                                    }
                                    ForEach(
                                        channels
                                    ) { channel in
                                        channelButtonView(channel: channel)
                                    }
                                } else {
                                    ForEach(
                                        channels
                                    ) { channel in
                                        channelButtonView(channel: channel)
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text("Direct Messages")
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func channelButtonView(channel: Channel) -> some View {
        CustomButton {
            selection = channel
        } label: {
            ChannelView(channel: channel)
                .environmentObject(discordWebSocket)
                .padding(1)
                .padding(.vertical, 3)
        } background: { isHovered in
            if let selection = selection, selection.id == channel.id {
                AnyView(buttonClickedView)
            } else if isHovered {
                AnyView(buttonHighlightView)
            } else {
                AnyView(buttonPlainView)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var buttonClickedView: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2))
    }
    
    private var buttonHighlightView: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1))
    }
    
    private var buttonPlainView: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.clear)
    }
    
    @ViewBuilder
    private var searchBarView: some View {
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .padding(8)
            TextField("Find a conversation", text: $searchText)
                .textFieldStyle(.plain)
        }
        .background(backgroundView)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.1))
            )
    }
}
