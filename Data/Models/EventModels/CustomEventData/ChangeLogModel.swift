//
//  ChangeLog.swift
//  Scoop
//
//  Created by Art Ostin on 31/01/2026.
//

import SwiftUI
import FirebaseFirestore

struct ChangeLogEntry: Codable, Identifiable {
    @DocumentID var id: String?
    @ServerTimestamp var timestamp: Date?
    let updateNumber: Int
    let editedByUserId: String
    let changes: [ChangeItem]
}

struct ChangeItem: Codable {
    let field: String          // e.g. "time" or "location.name"
    let oldValue: ChangeValue
    let newValue: ChangeValue
}


enum ChangeValue: Codable, Equatable {
    case proposedTimes([Date])
}
