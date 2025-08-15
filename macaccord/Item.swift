//
//  Item.swift
//  macaccord
//
//  Created by đỗ quyên on 16/08/2025.
//

import Foundation
import SwiftData

// Item schema
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
