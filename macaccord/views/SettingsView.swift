//
//  SettingsView.swift
//  macaccord
//
//  Created by đỗ quyên on 16/9/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Account")) {
                    Button("Log out") {
                        Task {
                            KeychainHelper.standard.delete(service: "auth", account: "token")
                            isLoggedIn = false
                        }
                    }
                }
                Section(header: Text("About")) {
                    Text("App version 1.0")
                        .font(.caption)
                }
            }
            
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

#Preview {
    SettingsView()
}
