//
//  MessageView.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//

import Foundation
import SwiftUI




// MARK: - Message List View
struct MessageListView: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var userData: UserData
    
    let channelId: String
    let timeFrame = 10
    
    var body: some View {
        VStack {
            // Message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.messages.indices, id: \.self) { idx in
                            let isJustText =
                                (idx + 1 < viewModel.messages.count)
                                && (viewModel.messages[idx + 1].author.id == viewModel.messages[idx].author.id)
                                && Int(viewModel.messages[idx].timestamp.timeIntervalSince(viewModel.messages[idx + 1].timestamp) / 60) <= timeFrame
                            MessageView(message: viewModel.messages[idx], isJustText: isJustText)
                                .id(viewModel.messages[idx].id)
                                .rotationEffect(.degrees(180))
                                .scaleEffect(x: -1.0, y: 1.0)
                                .environmentObject(userData)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .opacity
                                    )
                                )
                                .scrollTargetLayout()
                        }
                        Text("...")
                            .onAppear {
                                Task {
                                    Log.ui.info("Fetching more messages")
                                    await viewModel.fetchMessages(channel: channelId, isExtending: true)
                                }
                            }
                    }
                }
                .rotationEffect(.degrees(180))
                .scaleEffect(x: -1.0, y: 1.0)
                //.scrollTargetBehavior(.viewAligned)
                // .defaultScrollAnchor(.bottom)
                .onChange(of: viewModel.messages.first?.id, initial: false) {
                    if let firstMessage = viewModel.messages.first {
                        withAnimation(.bouncy(duration: 0.3)) {
                            proxy.scrollTo(firstMessage.id, anchor: .top)
                        }
                    }
                }
                Spacer()
            }
            .animation(.bouncy(duration: 0.3), value: viewModel.messages.count)
        }
    }
}
