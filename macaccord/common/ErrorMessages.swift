//
//  ErrorMessages.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import Foundation

enum HTTPError : LocalizedError {
    case statusCode(Int)
    case errorMessage(String)
    case invalidResponse
    case invalidURL
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .statusCode(let code):
            return "Request failed with status code \(code)."
        case .errorMessage(let message):
            return "Failed to fetch data: \(message)."
        case .invalidResponse:
            return "Invalid response from the server."
        case .invalidURL:
            return "Invalid URL"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
