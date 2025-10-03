//
//  DelayedView.swift
//  macaccord
//
//  Created by đỗ quyên on 3/10/25.
//

import SwiftUI

struct DelayedView<Content: View, Placeholder: View>: View {
    @State private var showContent = false
    
    private let content: () -> Content
    private let placeholder: () -> Placeholder
    private let delay: TimeInterval

    init(content: @escaping () -> Content, placeholder: @escaping () -> Placeholder, delay: TimeInterval = 0.2) {
        self.content = content
        self.placeholder = placeholder
        self.delay = delay
    }
    
    var body: some View {
        VStack {
            if showContent {
                content()
                    //.transition(.opacity)
            } else {
                placeholder()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                    showContent = true
                }
            }
        }
        .onDisappear {
            withAnimation {
                showContent = false
            }
        }
    }
}

// Extension for convenience when not specifying a placeholder
extension DelayedView where Placeholder == EmptyView {
    init(content: @escaping () -> Content) {
        self.init(content: content, placeholder: { EmptyView() })
    }
}
