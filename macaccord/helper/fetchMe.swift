//
//  fetchMe.swift
//  macaccord
//
//  Created by đỗ quyên on 18/9/25.
//

import Foundation

func fetchMe() async throws -> User {
    let decoder = MessageDecoder.createDecoder()
    
    guard let url = URL(string: "https://discord.com/api/v9/users/@me") else {
        throw HTTPError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(KeychainHelper.standard.read(service: "auth", account: "token"), forHTTPHeaderField: "Authorization")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw HTTPError.statusCode(httpResponse.statusCode)
        }
        
        // Decode the json
        let me = try decoder.decode(User.self, from: data)
        return me
    } catch {
        throw HTTPError.errorMessage(error.localizedDescription)
    }
}
