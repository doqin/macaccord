//
//  ChannelViewModel.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//


@MainActor
class ChannelViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var isLoading = true // Maybe switch to false later?
    @Published var errorMessage: String? = nil
    
    private var decoder: JSONDecoder = MessageDecoder.createDecoder()
    
    func fetchChannels() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: "https://discord.com/api/v9/users/@me/channels?limit=50") else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(KeychainHelper.standard.read(service: "auth", account: "token"), forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                errorMessage = "Server error: \(httpResponse.statusCode)"
                return
            }
            
            // Decode the json
            channels = try decoder.decode([Channel].self, from: data)
            for idx in channels.indices {
                if let uint64Value = UInt64(channels[idx].last_message_id ?? "1420070400000") {
                    channels[idx].last_message_timestamp = snowflakeToDate(uint64Value)
                } else {
                    Log.general.warning("Could not get timestamp for channel \(self.channels[idx].id)")
                }
            }
        } catch {
            errorMessage = "Failed to fetch: \(error.localizedDescription)"
        }
    }
}