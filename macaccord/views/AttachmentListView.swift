import Foundation
import _AVKit_SwiftUI
import SwiftUI
import AVFoundation

//
//  MediaPlayerView.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//


// MARK: - Media Player View
struct MediaPlayerView: View {
    let player: AVPlayer
    
    init?(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        self.player = AVPlayer(url: url)
    }
    
    var body: some View {
        VideoPlayer(player: player) // Works for audio too
            .frame(height: 360)
            .onDisappear {
                player.pause()
            }
    }
}

// MARK: - Attachment List View
struct AttachmentListView: View {
    let attachments: [Attachment]
    var body: some View {
        VStack(alignment: .leading) {
            ImageAttachmentGridView(attachments: attachments.filter{ $0.content_type?.hasPrefix("image/") == true })
            MediaAttachmentListView(attachments: attachments.filter{$0.content_type?.hasPrefix("audio/") == true || $0.content_type?.hasPrefix("video/") == true })
        }
    }
}

// MARK: - Media Attachment List View
struct MediaAttachmentListView: View {
    let attachments: [Attachment]
    
    var body: some View {
        VStack {
            ForEach(attachments) { attachment in
                if let mediaView = MediaPlayerView(urlString: attachment.url) {
                    mediaView
                } else {
                    ProgressView("Loading media...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Image Attachment Grid View
struct ImageAttachmentGridView: View {
    let attachments: [Attachment]

    var body: some View {
        if attachments.count == 1 {
            // Single attachment: keep aspect ratio, cap height
            AttachmentImageView(urlString: attachments[0].url)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400, maxHeight: 300, alignment: .leading) // Add explicit max constraints
                .clipped()
                .cornerRadius(6)
        } else if attachments.count == 2 {
            // Two side-by-side squares
            HStack(spacing: 4) {
                ForEach(attachments.prefix(2), id: \.self) { attachment in
                    AttachmentImageView(urlString: attachment.url)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: 150, maxHeight: 150) // Constrain individual images
                        .clipped()
                        .cornerRadius(6)
                }
            }
            .frame(maxWidth: 304) // 2 * 150 + spacing
        } else if attachments.count == 3 {
            // One large + two small
            HStack(spacing: 4) {
                AttachmentImageView(urlString: attachments[0].url)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200) // Fixed size for predictable layout
                    .clipped()
                    .cornerRadius(6)
                
                VStack(spacing: 4) {
                    AttachmentImageView(urlString: attachments[1].url)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 98, height: 98) // Fixed size
                        .clipped()
                        .cornerRadius(6)
                    AttachmentImageView(urlString: attachments[2].url)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 98, height: 98) // Fixed size
                        .clipped()
                        .cornerRadius(6)
                }
            }
            .frame(maxWidth: 302) // 200 + 98 + spacing
        } else if attachments.count >= 4 {
            // 2x2 grid, last one shows +N
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(150), spacing: 4), count: 2), spacing: 4) {
                ForEach(attachments.prefix(4).indices, id: \.self) { i in
                    ZStack {
                        AttachmentImageView(urlString: attachments[i].url)
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 150, height: 150) // Fixed size
                            .clipped()
                            .cornerRadius(6)
                        
                        if i == 3 && attachments.count > 4 {
                            Color.black.opacity(0.5)
                                .cornerRadius(6)
                            Text("+\(attachments.count - 4)")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(maxWidth: 304) // 2 * 150 + spacing
        }
    }
}
