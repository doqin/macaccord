//
//  AttachmentImageView.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//


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