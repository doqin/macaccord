//
//  ImportedAttachmentsView.swift
//  macaccord
//
//  Created by đỗ quyên on 2/10/25.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLookThumbnailing

struct ImportedAttachmentsView: View {
    
    @Binding var fileURLs: [URL]
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(fileURLs, id: \.path) { fileURL in
                        ZStack {
                            VStack {
                                if isImage(fileURL) {
                                    SecurityScopedImage(url: fileURL, placeholder: {
                                        placeholder(fileURL: fileURL)
                                            .padding(4)
                                    }, label: { nsImage in
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .scaledToFit()
                                            .background(.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    })
                                } else {
                                    // Show thumbnail or fallback
                                    FileThumbnailView(fileURL: fileURL)
                                }
                                Text(fileURL.lastPathComponent)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            VStack {
                                HStack {
                                    Spacer()
                                    Button {
                                        fileURLs.remove(at: fileURLs.firstIndex(of: fileURL)!)
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(8)
                                    .background(
                                        fileBackgroundView
                                    )
                                }
                                Spacer()
                            }
                            
                        }
                        .padding(8)
                        .frame(width: 200, height: 200)
                        .background(
                            fileBackgroundView
                        )
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                    }
                }
                .padding(8)
                .animation(.bouncy(duration: 0.3), value: fileURLs.count)
            }
        }
        .padding(8)
    }
    
    @ViewBuilder
    private var fileBackgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .stroke(Color.gray, lineWidth: 0.5)
            )
    }
    
    private func isImage(_ url: URL) -> Bool {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return type.conforms(to: .image)
    }
    
    private func placeholder(fileURL: URL) -> some View {
        Image(systemName: "doc.fill")
            .font(.largeTitle)
    }
}

// MARK: - Thumbnail for non-images
struct FileThumbnailView: View {
    let fileURL: URL
    @State private var thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack {
                    Image(systemName: "text.document.fill")
                        .font(.largeTitle)
                    Text(fileURL.lastPathComponent)
                        .lineLimit(1)
                        .font(.caption)
                }
                .task {
                    await generateThumbnail()
                }
            }
        }
    }
    
    private func generateThumbnail() async {
        let size = CGSize(width: 100, height: 100)
        let scale: CGFloat = NSScreen.main?.backingScaleFactor
            ?? NSScreen.screens.first?.backingScaleFactor
            ?? 2.0
        
        let request = QLThumbnailGenerator.Request(
            fileAt: fileURL,
            size: size,
            scale: scale,
            representationTypes: .all
        )
        do {
            let result = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            await MainActor.run {
                self.thumbnail = result.nsImage
            }
        } catch {
            print("Failed to generate thumbnail:", error)
        }
    }
}

#Preview {
    ImportedAttachmentsView(
        fileURLs: .constant(
            [
                URL(string: "file:///Users/doqin/Downloads/dogdog.jpeg")!,
                URL(string: "file:///Users/doqin/Downloads/tan-nguyen--2mmVMKjGXo-unsplash.jpg")!
            ]
        )
    )
}
