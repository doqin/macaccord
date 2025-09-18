//
//  ImageErrorView.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//

import SwiftUI


struct ImageErrorView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray)
            .overlay(Image(systemName: "xmark.octagon.fill").foregroundColor(.white))
    }
}
