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
    @State var isImporterPresented: Bool = false
    
    @Binding var isSending: Bool
    @Binding var isOpeningPicker: Bool
    @Binding var fileURLs: [URL]
    
    var decoder: JSONDecoder = MessageDecoder.createDecoder()
    
    let channelId: String
    
    var body: some View {
        HStack(spacing: 0) {
            // The attachment button
            attachmentButtonView
                .padding(8)
            
            // The actual Text field
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
            // The send button
            sendButtonView
                .padding(8)
        }
        .padding(.horizontal, 8)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                fileURLs = urls
            case .failure(let error):
                Log.general.error("Error importing: \(error)")
            }
        }
    }
    
    var buttonHighlightView: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1))
    }
    
    var buttonPlainView: some View {
        RoundedRectangle(cornerRadius: 8).fill(Color.clear)
    }
    
    @ViewBuilder
    var attachmentButtonView: some View {
        CustomButton(
            action: { isImporterPresented = true },
            label: {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .font(.largeTitle)
                    .padding(8)
            },
            background: { isHovered in
                if isHovered {
                    AnyView(buttonHighlightView)
                } else {
                    AnyView(buttonPlainView)
                }
            }
        )
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    var emoteButtonView: some View {
        CustomButton {
            isOpeningPicker.toggle()
        } label: {
            Image(systemName: "face.smiling")
                .foregroundColor(.gray)
                .font(.title)
                .padding(8)
        } background: { isHovered in
            if isHovered {
                AnyView(buttonHighlightView)
            } else {
                AnyView(buttonPlainView)
            }
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
        if !textFieldMessage.isEmpty || !fileURLs.isEmpty {
            Task {
                do {
                    isSending = true
                    defer { isSending = false }
                    let messageToSend = textFieldMessage
                    textFieldMessage = ""
                    Log.network.info("Sending message '\(messageToSend)' to channel '\(channelId)'...")
                    try await sendMessage(message: messageToSend, fileURLs: fileURLs)
                    Log.network.info("Sent message '\(messageToSend)'!")
                    fileURLs = []
                    // viewModel.messages.count > 0 ? viewModel.messages.prepend(sentMessage) : viewModel.messages.append(sentMessage)
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    func sendMessage(message: String, fileURLs: [URL]) async throws {
        guard let url = URL(
            string: "https://discord.com/api/v9/channels/\(channelId)/messages"
        ) else {
            throw URLError(.badURL)
        }
        
        let payload: [String: Any] = [
            "content": message
        ]
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // Add payload_json
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"payload_json\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(payloadData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add each file
        for (index, fileURL) in fileURLs.prefix(10).enumerated() { // Discord max 10
            // Start security access
            do {
                if fileURL.startAccessingSecurityScopedResource() {
                    defer { fileURL.stopAccessingSecurityScopedResource() }
                            
                    let fileData = try Data(contentsOf: fileURL)
                    let fileName = fileURL.lastPathComponent
                    
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"files[\(index)]\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
                    body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
                    body.append(fileData)
                    body.append("\r\n".data(using: .utf8)!)
                }
            } catch (let error){
                Log.general.error("Error importing file: \(error.localizedDescription)")
                throw error
            }
        }
        
        // End
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(KeychainHelper.standard.read(service: "auth", account: "token"), forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                throw HTTPError.statusCode(httpResponse.statusCode)
            }
        } catch {
            throw error
        }
    }
    
    func generateNonce() -> String {
        let nonce = UInt64.random(in: 1_000_000_000_000_000_000...9_999_999_999_999_999_999)
        return String(nonce)
    }
}
