// MARK: - Text Field View
struct TextFieldView: View {
    @State private var message: String = ""
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    @Binding var isSending: Bool
    
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
                TextField("Message", text: $message)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .onSubmit {
                        Task {
                            do {
                                isSending = true
                                defer { isSending = false }
                                let messageToSend = message
                                message = ""
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
                    .alert("Error", isPresented: $showErrorAlert, actions: {
                        Button("OK", role: .cancel) {}
                    }, message: {
                        Text(errorMessage)
                    })
                // The Emote button
                Button {
                    // Doesn't do anything yet
                } label: {
                    Image(systemName: "face.smiling.inverse")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                .padding(8)
                .buttonStyle(.plain)
            }
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 999).stroke(style: StrokeStyle(lineWidth: 0.5)).fill(Color.gray))
            )
            // The send button
            Button {
                if !message.isEmpty {
                    Task {
                        do {
                            isSending = true
                            defer { isSending = false }
                            let messageToSend = message
                            message = ""
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
            } label: {
                if message.isEmpty {
                    Image(systemName: "paperplane.circle")
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                } else {
                    Image(systemName: "paperplane.circle.fill")
                        .foregroundColor(.blue)
                        .font(.largeTitle)
                }
            }
            .padding(8)
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 4)
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