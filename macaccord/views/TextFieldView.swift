//
//  TextFieldView.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//

import SwiftUI
import Foundation


struct TextFieldView: View {
    @Binding var textFieldMessage: String
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    @Binding var isSending: Bool
    @Binding var isOpeningPicker: Bool
    
    var decoder: JSONDecoder = MessageDecoder.createDecoder()
    
    let channelId: String
    
    var body: some View {
        HStack(spacing: 0) {
            // The attachment button
            Button {
                // Doesn't do anything yet
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .font(.largeTitle)
            }
            .padding(8)
            .buttonStyle(.plain)
            // The actual Text field
            HStack {
                TextField("Message", text: $textFieldMessage)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .onSubmit {
                        sendMessageHelper()
                    }
                    .alert("Error", isPresented: $showErrorAlert, actions: {
                        Button("OK", role: .cancel) {}
                    }, message: {
                        Text(errorMessage)
                    })
                // The Emote button
                emoteButtonView
                .padding(8)
            }
            .frame(height: 32)
            .background(
                backgroundView
            )
            // The send button
            sendButtonView
            .padding(8)
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    var backgroundView: some View {
        RoundedRectangle(cornerRadius: 999)
            .fill(Color.gray.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 999).stroke(style: StrokeStyle(lineWidth: 0.5)).fill(Color.gray))
    }
    
    @ViewBuilder
    var emoteButtonView: some View {
        Button {
            isOpeningPicker.toggle()
        } label: {
            Image(systemName: "face.smiling.inverse")
                .foregroundColor(.gray)
                .font(.title2)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    var sendButtonView: some View {
        Button {
            sendMessageHelper()
        } label: {
            if textFieldMessage.isEmpty {
                Image(systemName: "paperplane.circle")
                    .foregroundColor(.gray)
                    .font(.largeTitle)
            } else {
                Image(systemName: "paperplane.circle.fill")
                    .foregroundColor(.blue)
                    .font(.largeTitle)
            }
        }
        .buttonStyle(.plain)
    }
    
    func sendMessageHelper() {
        if !textFieldMessage.isEmpty {
            Task {
                do {
                    isSending = true
                    defer { isSending = false }
                    let messageToSend = textFieldMessage
                    textFieldMessage = ""
                    Log.network.info("Sending message '\(messageToSend)' to channel '\(channelId)'...")
                    let sentMessage = try await sendMessage(message: messageToSend)
                    Log.network.info("Sent message '\(sentMessage.content)'!")
                    // viewModel.messages.count > 0 ? viewModel.messages.prepend(sentMessage) : viewModel.messages.append(sentMessage)
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    func sendMessage(message: String) async throws -> Message {
        guard let url = URL(
            string: "https://discord.com/api/v9/channels/\(channelId)/messages"
        ) else {
            throw URLError(.badURL)
        }
        
        let parameters: [String: Any] = [
            "content": message,
            "flags": 0,
            "mobile_network_type": "unknown",
            "nonce": generateNonce(),
            "tts": false
        ]
        let jsonBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(KeychainHelper.standard.read(service: "auth", account: "token"), forHTTPHeaderField: "Authorization")
        request.httpBody = jsonBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                throw HTTPError.statusCode(httpResponse.statusCode)
            }
            
            let message = try decoder.decode(Message.self, from: data)
            return message
        } catch {
            throw error
        }
    }
    
    func generateNonce() -> String {
        let nonce = UInt64.random(in: 1_000_000_000_000_000_000...9_999_999_999_999_999_999)
        return String(nonce)
    }
}
