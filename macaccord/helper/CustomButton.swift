//
//  CustomButton.swift
//  macaccord
//
//  Created by đỗ quyên on 2/10/25.
//

import SwiftUI

struct CustomButton<Label: View, Background: View>: View {
    
    @State private var isHovered: Bool = false
    
    let action: () -> Void
    let label: () -> Label
    let background: (Bool) -> Background
    
    var body: some View {
        Button {
            action()
        } label: {
            label()
            .onHover { isHovering in
                isHovered = isHovering
            }
        }
        .background(alignment: .center) {
            background(isHovered)
        }
    }
}
