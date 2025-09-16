//
//  ImageHandler.swift
//  macaccord
//
//  Created by đỗ quyên on 17/08/2025.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Image Cache Manager
@MainActor
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, NSImage>()
    private let urlSession: URLSession
    
    private init() {
        // Configure cache
        cache.countLimit = 100 // Adjust based on your needs
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Configure URL session with caching
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024, // 20MB memory
            diskCapacity: 100 * 1024 * 1024,  // 100MB disk
            diskPath: nil
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.urlSession = URLSession(configuration: config)
    }
    
    func loadImage(from url: URL) async throws -> NSImage {
        let cacheKey = NSString(string: url.absoluteString)
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Load data from network/disk cache
        let (data, _) = try await urlSession.data(from: url)
        
        // Create image on main actor (since NSImage isn't Sendable)
        guard let image = NSImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        
        // Store in memory cache
        cache.setObject(image, forKey: cacheKey)
        
        return image
    }
    
    func clearCache() {
        cache.removeAllObjects()
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }
}

// MARK: - Simple Cached AsyncImage View
struct CachedAsyncImage: View {
    let url: URL?
    let placeholder: Image
    let errorImage: Image
    
    @State private var image: Image?
    @State private var isLoading = false
    @State private var hasError = false
    
    init(
        url: URL?,
        placeholder: Image = Image(systemName: "photo"),
        errorImage: Image = Image(systemName: "photo.fill")
    ) {
        self.url = url
        self.placeholder = placeholder
        self.errorImage = errorImage
    }
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
            } else if hasError {
                errorImage
                    .foregroundColor(.red)
            } else {
                placeholder
                    .foregroundColor(.secondary)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                    }
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else {
            image = nil
            hasError = false
            isLoading = false
            return
        }
        
        isLoading = true
        hasError = false
        image = nil
        
        do {
            let nsImage = try await ImageCacheManager.shared.loadImage(from: url)
            image = Image(nsImage: nsImage)
            hasError = false
        } catch {
            hasError = true
            image = nil
        }
        
        isLoading = false
    }
}

// MARK: - Custom Content Version (if you need more control)
struct CachedAsyncImageWithContent<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .task(id: url) {
                await loadImage()
            }
    }
    
    private func loadImage() async {
        guard let url = url else {
            phase = .empty
            return
        }
        
        phase = .empty
        
        do {
            let nsImage = try await ImageCacheManager.shared.loadImage(from: url)
            phase = .success(Image(nsImage: nsImage))
        } catch {
            phase = .failure(error)
        }
    }
}

// MARK: - AvatarView
struct AvatarView: View {
    let userId: String
    let size: CGFloat
    var isShowStatus: Bool = false
    
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(
                url: userData.users[userId]?.avatarURL,
                placeholder:
                    Image(systemName: "person.circle.fill")
                    .resizable()
                ,
                errorImage:
                    Image(systemName: "questionmark.circle")
                    .resizable()
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
                switch userData.users[userId]?.status ?? "offline" {
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

// MARK: - AttachmentImageView
struct AttachmentImageView: View {
    let urlString: String
    @State private var loadingState: LoadingState = .loading
    
    enum LoadingState {
        case loading
        case loaded
        case failed
    }
    
    var body: some View {
        Group {
            if let url = URL(string: urlString), isValidImageURL(url) {
                CachedAsyncImageWithContent(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.2))
                        .onAppear {
                            loadingState = .loading
                        }
                    case .success(let image):
                        image
                            .resizable()
                            //.scaledToFit()
                            // .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .onAppear {
                                loadingState = .loaded
                            }
                    case .failure(let error):
                        ImageErrorView()
                            .onAppear {
                                Log.network.error("Failed to load image from: \(urlString):\n \(error)")
                                loadingState = .failed
                            }
                    @unknown default:
                        ImageErrorView()
                    }
                }
                .animation(.easeInOut(duration: 1), value: loadingState)
            } else {
                ImageErrorView()
            }
        }
    }
    
    private func isValidImageURL(_ url: URL) -> Bool {
        // Basic validation - you might want to add more checks
        let validSchemes = ["http", "https", "file"]
        guard let scheme = url.scheme?.lowercased(),
              validSchemes.contains(scheme) else {
            return false
        }
        
        // Check for common image extensions (optional)
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "heic", "svg"]
        let pathExtension = url.pathExtension.lowercased()
        
        // Allow URLs without extensions (many CDNs don't use them)
        return pathExtension.isEmpty || imageExtensions.contains(pathExtension)
    }
}

// MARK: - ImageErrorView
struct ImageErrorView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray)
            .overlay(Image(systemName: "xmark.octagon.fill").foregroundColor(.white))
    }
}

// MARK: - Helper extension
extension View {
    func reverseMask<Mask: View>(alignment: Alignment = .center, @ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}

#Preview {
    let userData = UserData()
    userData.users["672642067050135562"] = User(id: "672642067050135562", username: "gayce", avatar: "b04f7a78903118afb68d17f079599a5f", status: "idle")
    return AvatarView(userId: "672642067050135562", size: 128, isShowStatus: true)
            .environmentObject(userData)
            .frame(width: 256, height: 256)
}
