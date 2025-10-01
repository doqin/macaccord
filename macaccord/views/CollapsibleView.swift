//
//  CollapsibleView.swift
//  macaccord
//
//  Created by đỗ quyên on 1/10/25.
//

import SwiftUI

struct CollapsibleView<HeaderView: View, ContentView: View>: View {
    @State private var isExpanded = true
    @ViewBuilder let header: () -> HeaderView
    @ViewBuilder let content: () -> ContentView
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content()
        } label: {
            header()
        }
        .padding(4)
    }
}

#Preview {
    CollapsibleView(header: {
        Text("Test")
            .font(.title)
    }, content: {
        Text("test test!")
            .font(.body)
    })
}
