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

    //Custom Encoder and Decoder — write the payload directly with no
    //case-name wrapper. The sibling `ChangeItem.field` already carries
    //the discriminator (e.g. "proposedTimes"), so we don't need to
    //repeat it here.
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .proposedTimes(let dates):
            try container.encode(dates)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dates = try? container.decode([Date].self) {
            self = .proposedTimes(dates)
            return
        }
        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath,
                  debugDescription: "Unknown ChangeValue payload")
        )
    }
}
