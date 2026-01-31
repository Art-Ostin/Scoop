//
//  ProposedTimes.swift
//  Scoop
//
//  Created by Art Ostin on 30/01/2026.
//

import SwiftUI

struct ProposedTimes: Codable, Equatable  {
    
    static let maxCount = 3
    
    private(set) var values: [Date]
    
    init(values: [Date] = []) {
        self.values = Array(values.prefix(Self.maxCount))
    }
    
    mutating func add(_ date: Date) -> Bool {
        guard values.count < Self.maxCount, !values.contains(date) else {return false }
        values.append(date)
        return true
    }
    
    mutating func remove(_ date: Date) {
        values.removeAll {$0 == date }
    }
    
    mutating func toggle(_ date: Date) {
        if values.contains(date) {
            remove(date)
        } else {
            _ = add(date)
        }
    }
    
    var dates: [Date] {
        values
    }
    
    //Don't worry about understanding Yet
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode([Date].self)
        try self.init(from: decoded as! Decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}
