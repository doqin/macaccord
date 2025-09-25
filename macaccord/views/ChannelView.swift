//
//  ChannelView.swift
//  macaccord
//
//  Created by đỗ quyên on 25/9/25.
//

import SwiftUI

struct ChannelView: View {
    
    let channel: Channel
    let overlap: CGFloat = 16
    let avatarSize: CGFloat = 32
    
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

#Preview {
    let userData = UserData()
    userData.users["672642067050135562"] = User(id: "672642067050135562", username: "gayce", avatar: "b04f7a78903118afb68d17f079599a5f", status: "idle")
    return ChannelView(channel: Channel(id: "123123", recipients: [userData.users["672642067050135562"]!]))
        .environmentObject(userData)
        .frame(width: 128, height: 64)
}
