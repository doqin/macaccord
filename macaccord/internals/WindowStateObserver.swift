//
//  WindowStateObserver.swift
//  macaccord
//
//  Created by đỗ quyên on 17/9/25.
//

import SwiftUI
import AppKit

struct WindowStateObserver: NSViewRepresentable {
    @Binding var isKeyWindow: Bool
    @Binding var isMiniaturized: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window ?? NSApp.windows.first {
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didBecomeKeyNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    isKeyWindow = true
                }

                NotificationCenter.default.addObserver(
                    forName: NSWindow.didResignKeyNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    isKeyWindow = false
                }

                NotificationCenter.default.addObserver(
                    forName: NSWindow.didMiniaturizeNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    isMiniaturized = true
                }

                NotificationCenter.default.addObserver(
                    forName: NSWindow.didDeminiaturizeNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    isMiniaturized = false
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
