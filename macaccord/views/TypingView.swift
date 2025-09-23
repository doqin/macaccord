//
//  TypingView.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//

import SwiftUI

struct ThreeDotLoadingView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 4, height: 4)
                    .scaleEffect(animate ? 0.3 : 1)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

struct TypingView: View {
    
    @EnvironmentObject var userData: UserData
    
    @Binding var isTyping: Bool
    @Binding var typingStartInfo: TypingStart?
    
    var body: some View {
        VStack {
            if isTyping {
                HStack(spacing: 4) {
                    CachedAsyncImage(
                        url: userData.users[typingStartInfo?.user_id ?? "0"]?.avatarURL,
                        placeholder:
                            Image(systemName: "person.circle.fill")
                            .resizable()
                        ,
                        errorImage:
                            Image(systemName: "questionmark.circle")
                            .resizable()
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
                    .padding(.horizontal, 16/6)
                    Text(userData.users[typingStartInfo?.user_id ?? "0"]?.displayName ?? "unknown person")
                        .font(.callout)
                    Text("is typing")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    ThreeDotLoadingView()
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.bouncy(duration: 0.4), value: isTyping)
    }
}

#Preview {
    /*
    let userData = UserData()
    userData.users["672642067050135562"] = User(id: "672642067050135562", username: "gayce", avatar: "b04f7a78903118afb68d17f079599a5f", status: "idle")
    return TypingView(userId: "672642067050135562", channelId: "1406300552857649253")
        .environmentObject(userData)
        .frame(width: 256, height: 256)
     */
}
