//
//  SetupView.swift
//  macaccord
//
//  Created by đỗ quyên on 25/9/25.
//

import SwiftUI

struct SetupView: View {
    @Binding var setupMessage: String
    var body: some View {
        VStack {
            ProgressView()
            Text(setupMessage)
        }
    }
}
