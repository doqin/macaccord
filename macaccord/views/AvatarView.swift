//
//  AvatarView.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//

import SwiftUI


// MARK: - AvatarView
struct AvatarView: View {
    let userId: String
    let size: CGFloat
    var isShowStatus: Bool = false
    
    @EnvironmentObject var discordWebSocket: DiscordWebSocket
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(
                url: discordWebSocket.users[userId]?.avatarURL,
                placeholder:
                    AnyView(
                    Image(systemName: "person.circle.fill")
                    .resizable())
                ,
                errorImage:
                    AnyView(
                    Image(systemName: "questionmark.circle")
                    .resizable())
            )
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .padding(.horizontal, size/6)
            .reverseMask {
                if isShowStatus {
                    Circle()
                        .frame(width: size/2, height: size/2)
                        .offset(x: size/2 - size/8, y: size/3)
                }
            }
            if isShowStatus {
                switch discordWebSocket.users[userId]?.status ?? "offline" {
                case "online":
                    Circle()
                        .fill(Color(red: 66.0/255, green: 162.0/255, blue: 90.0/255)) // green
                        .frame(width: size/3, height: size/3)
                        .offset(x: -size/8)
                case "offline":
                    Circle()
                        .fill(Color(red: 130.0/255, green: 131.0/255, blue: 139.0/255)) // gray
                        .frame(width: size/3, height: size/3)
                        .reverseMask {
                            Circle()
                                .frame(width: size/6, height: size/6)
                        }
                        .offset(x: -size/8)
                case "idle":
                    Circle()
                        .fill(Color(red: 202.0/255, green: 150.0/255, blue: 84.0/255)) // yellow
                        .frame(width: size/3, height: size/3)
                        .reverseMask {
                            Circle()
                                .frame(width: size/4, height: size/4)
                                .offset(x: -size/12, y: -size/12)
                        }
                        .offset(x: -size/8)
                case "dnd":
                    Circle()
                        .fill(Color(red: 216.0/255, green: 58.0/255, blue: 66.0/255)) // red
                        .frame(width: size/3, height: size/3)
                        .reverseMask {
                            RoundedRectangle(cornerRadius: 999)
                                .frame(width: size/4, height: size/10)
                        }
                        .offset(x: -size/8)
                default:
                    EmptyView()
                }
            }
        }
    }
}
