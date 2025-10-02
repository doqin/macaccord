//
//  SecurityScopedImage.swift
//  macaccord
//
//  Created by đỗ quyên on 2/10/25.
//

import SwiftUI

struct SecurityScopedImage<Placeholder: View, Label: View>: View {
    
    let url: URL
    
    @State private var nsImage: NSImage? = nil
    @ViewBuilder var placeholder: () -> Placeholder
    @ViewBuilder var label: (NSImage) -> Label
    
    var body: some View {
        Group {
            if let nsImage = nsImage {
                label(nsImage)
            } else {
                placeholder()
            }
        }
        .task {
            await loadImage(url: url)
        }
    }
    
    private func loadImage(url: URL) async {
        do {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                
                let fileData = try Data(contentsOf: url)
                nsImage = NSImage(data: fileData)
            }
        } catch {
            Log.general.error("Error loading image: \(error.localizedDescription)")
        }
    }
}
