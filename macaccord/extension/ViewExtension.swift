//
//  ViewExtension.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//

import SwiftUI

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
