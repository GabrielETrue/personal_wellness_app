//
//  Item.swift
//  Personal Wellness App
//
//  Created by Gabriel True on 4/18/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
