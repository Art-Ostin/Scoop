//
//  ChangeLog.swift
//  Scoop
//
//  Created by Art Ostin on 31/01/2026.
//

import SwiftUI
import FirebaseFirestore

enum ChangeType: String, Codable {
    case newTime, newEvent
}

struct ChangeLogEntry: Codable {
    var timestamp: Date = Date()
    let editedByUserId: String
    let changes: [ChangeItem]
}

struct ChangeItem: Codable {
    let changeType: String          // e.g. "time" or "location.name"
    let oldValue: ChangeValue
    let newValue: ChangeValue
}


enum ChangeValue: Equatable {
    case proposedTimes([Date])
    case string(String)
}

extension ChangeValue: Codable {

    //Writes the payload with no case-name wrapper — ChangeItem.changeType already carries the discriminator
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .proposedTimes(let dates):
            try container.encode(dates)
        case .string(let value):
            try container.encode(value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dates = try? container.decode([Date].self) {
            self = .proposedTimes(dates)
            return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath,
                  debugDescription: "Unknown ChangeValue payload")
        )
    }
}
