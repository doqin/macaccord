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

