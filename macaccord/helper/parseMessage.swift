//
//  parseMessage.swift
//  macaccord
//
//  Created by đỗ quyên on 23/9/25.
//

import Foundation

func parseMessage(_ message: String) -> [MessagePart] {
    let regex = try! NSRegularExpression(pattern: "<(a?):([a-zA-Z0-9_]+):(\\d+)>")
    let nsMessage = message as NSString
    var parts: [MessagePart] = []
    
    var lastIndex = 0
    for match in regex.matches(in: message, range: NSRange(location: 0, length: nsMessage.length)) {
        let fullRange = match.range
        let prefixRange = NSRange(location: lastIndex, length: fullRange.location - lastIndex)
        
        if prefixRange.length > 0 {
            parts.append(.text(nsMessage.substring(with: prefixRange)))
        }
        
        let animated = nsMessage.substring(with: match.range(at: 1)) == "a"
        let name = nsMessage.substring(with: match.range(at: 2))
        let id = nsMessage.substring(with: match.range(at: 3))
        
        parts.append(.emote(name: name, id: id, animated: animated))
        
        lastIndex = fullRange.location + fullRange.length
    }
    
    // Append trailing text
    if lastIndex < nsMessage.length {
        parts.append(.text(nsMessage.substring(from: lastIndex)))
    }
    
    return parts
}
