//
//  ChangeLog.swift
//  Scoop
//
//  Created by Art Ostin on 31/01/2026.
//

import SwiftUI
import FirebaseFirestore

struct ChangeLogEntry: Codable {
    var timestamp: Date = Date()
    let updateNumber: Int
    let editedByUserId: String
    let changes: ChangeItem
}

struct ChangeItem: Codable {
    let field: String          // e.g. "time" or "location.name"
    let oldValue: ChangeValue
    let newValue: ChangeValue
}


enum ChangeValue: Equatable {
    case proposedTimes([Date])
}

extension ChangeValue: Codable {
    private enum CodingKeys: String, CodingKey {
        case proposedTimes
    }

    
    //Custom Encoder and Decoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .proposedTimes(let dates):
            try container.encode(dates, forKey: .proposedTimes)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let dates = try container.decodeIfPresent([Date].self, forKey: .proposedTimes) {
            self = .proposedTimes(dates)
            return
        }
        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath,
                  debugDescription: "Unknown ChangeValue payload")
        )
    }
}
