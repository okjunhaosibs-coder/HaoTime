//
//  Item.swift
//  HaoTime
//
//  Created by Junhao Hu on 2026/5/5.
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
