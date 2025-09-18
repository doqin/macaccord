//
//  LoginView.swift
//  macaccord
//
//  Created by đỗ quyên on 16/9/25.
//

import SwiftUI

struct LoginView: View {
    @State private var token = ""
    @State private var errorMessage = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    var body: some View {
        VStack {
            Text("Enter your Discord Token")
                .font(.title)
            Text("(Sorry, no proper log in yet :P)")
                .font(.caption)
            SecureField("Token", text: $token)
                
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button("Log In") {
                Task {
                    await verify()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
    
    func verify() async {
        guard let url = URL(string: "https://discord.com/api/v9/users/@me/channels?limit=50") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("\(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                errorMessage = "Server error: \(httpResponse.statusCode)"
                return
            }
            KeychainHelper.standard.save(token, service: "auth", account: "token")
            isLoggedIn = true
        } catch {
            errorMessage = "Something went wrong: \(error.localizedDescription)"
        }
    }
}

#Preview {
    LoginView()
}
