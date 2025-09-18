//
//  MessageDecoder.swift
//  macaccord
//
//  Created by đỗ quyên on 18/08/2025.
//

import Foundation
import Collections

class MessageDecoder {
    
    // Private method to create configured decoder
    static func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Configure the date decoding strategy to handle both formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try with microseconds first
            if let date = DateFormatter.discordISO8601WithMicroseconds.date(from: dateString) {
                return date
            }
            
            // Try without microseconds
            if let date = DateFormatter.discordISO8601WithoutMicroseconds.date(from: dateString) {
                return date
            }
            
            // As a fallback, try ISO8601DateFormatter
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Try ISO8601DateFormatter without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString). Expected formats: 'yyyy-MM-dd'T'HH:mm:ss.SSSSSS+00:00' or 'yyyy-MM-dd'T'HH:mm:ss+00:00'"
            )
        }
        
        return decoder
    }
    
    // Decode a single message
    static func decodeMessage(from jsonData: Data) -> Message? {
        let decoder = createDecoder()
        
        do {
            return try decoder.decode(Message.self, from: jsonData)
        } catch {
            print("Decoding error: \(error)")
            return nil
        }
    }
    
    // Decode an array of messages
    static func decodeMessages(from jsonData: Data) -> Deque<Message>? {
        let decoder = createDecoder()
        
        do {
            return try decoder.decode(Deque<Message>.self, from: jsonData)
        } catch {
            print("Decoding error: \(error)")
            return nil
        }
    }
    
    // Decode either a single message or array of messages automatically
    static func decode(from jsonData: Data) -> Result<Deque<Message>, Error> {
        let decoder = createDecoder()
        
        // First try to decode as an array
        if let messages = try? decoder.decode(Deque<Message>.self, from: jsonData) {
            return .success(messages)
        }
        
        // If that fails, try to decode as a single message
        if let message = try? decoder.decode(Message.self, from: jsonData) {
            return .success([message])
        }
        
        // If both fail, return the array decoding error for more context
        do {
            let _ = try decoder.decode(Deque<Message>.self, from: jsonData)
            return .success([]) // This line should never be reached
        } catch {
            return .failure(error)
        }
    }
    
    // Helper function to format timestamps for display
    static func formatTimestamp(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = style
        return formatter.string(from: date)
    }
    
    // Helper function to get relative time (e.g., "2 hours ago")
    static func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

