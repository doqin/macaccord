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
    
    var body: some View {
        VStack {
            // Message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
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
                    }
                }
                .rotationEffect(.degrees(180))
                .scaleEffect(x: -1.0, y: 1.0)
                //.scrollTargetBehavior(.viewAligned)
                // .defaultScrollAnchor(.bottom)
                .onChange(of: viewModel.messages.count) {
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
