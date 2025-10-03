//
//  CachedAsyncImage.swift
//  macaccord
//
//  Created by đỗ quyên on 17/08/2025.
//

import SwiftUI
import Foundation
import Combine
import AppKit

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
        Log.network.debug("Loading image from network: \(url)")
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
    let placeholder: AnyView
    let errorImage: AnyView
    
    @State private var image: Image?
    @State private var isLoading = false
    @State private var hasError = false
    
    init(
        url: URL?,
        placeholder: AnyView = AnyView(Image(systemName: "photo")),
        errorImage: AnyView = AnyView(Image(systemName: "photo.fill"))
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

// MARK: - Animated image support for GIF (macOS)
struct AnimatedCachedImage: View {
    let url: URL?
    let placeholder: AnyView
    let errorImage: AnyView
    var contentMode: ContentMode = .fit
    
    @State private var nsImage: NSImage?
    @State private var isLoading = false
    @State private var hasError = false
    
    init(
        url: URL?,
        placeholder: AnyView = AnyView(Image(systemName: "photo")),
        errorImage: AnyView = AnyView(Image(systemName: "photo.fill")),
        contentMode: ContentMode = .fit
    ) {
        self.url = url
        self.placeholder = placeholder
        self.errorImage = errorImage
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let nsImage {
                AnimatedNSImageView(image: nsImage, contentMode: contentMode)
                    .aspectRatio(contentMode: contentMode)
                    .clipped()
            } else if hasError {
                errorImage
                    .foregroundColor(.red)
            } else {
                placeholder
                    .foregroundColor(.secondary)
            }
        }
        .task(id: url) {
            await load()
        }
    }
    
    @MainActor
    private func load() async {
        guard let url else {
            nsImage = nil
            hasError = false
            isLoading = false
            return
        }
        isLoading = true
        hasError = false
        nsImage = nil
        do {
            // Reuse the existing cache/loader
            let image = try await ImageCacheManager.shared.loadImage(from: url)
            nsImage = image
        } catch {
            hasError = true
            nsImage = nil
        }
        isLoading = false
    }
}

private struct AnimatedNSImageView: NSViewRepresentable {
    let image: NSImage
    var contentMode: ContentMode
    
    func makeNSView(context: Context) -> NSView {
        // Container view that will adopt SwiftUI's proposed size
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // The actual image view
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageAlignment = .alignCenter
        imageView.imageScaling = scaling(for: contentMode)
        imageView.animates = true
        imageView.image = image
        
        // Make it willing to stretch to the container size
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        // Add and pin to edges so it fills whatever size SwiftUI gives
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let imageView = nsView.subviews.compactMap({ $0 as? NSImageView }).first else { return }
        imageView.image = image
        imageView.imageScaling = scaling(for: contentMode)
        imageView.animates = true
    }
    
    private func scaling(for contentMode: ContentMode) -> NSImageScaling {
        switch contentMode {
        case .fit:
            // Preserves aspect ratio and fits inside the view's bounds
            return .scaleProportionallyUpOrDown
        case .fill:
            // Note: This distorts to fill. If you need "aspect fill" with cropping,
            // you'd need a custom layer-backed solution.
            return .scaleAxesIndependently
        @unknown default:
            return .scaleProportionallyUpOrDown
        }
    }
}
