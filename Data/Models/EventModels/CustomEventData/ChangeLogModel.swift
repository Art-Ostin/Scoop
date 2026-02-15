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
    let updateNumber: Int
    @ServerTimestamp var timestamp: Date?
    let editedByUserId: String?
    let changes: [ChangeItem]
}

struct ChangeItem: Codable {
    let field: String          // e.g. "time" or "location.name"
    let oldValue: ChangeValue?
    let newValue: ChangeValue?
}

enum ChangeValue: Codable, Equatable {
    
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case eventType(Event.EventType)
    case eventLocation(EventLocation)
    case stringArray([String])
    case null

    enum CodingKeys: String, CodingKey { case type, value }
    enum ValueType: String, Codable {
        case string, int, double, bool, date, eventType, eventLocation, stringArray, null
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        switch type {
        case .string: self = .string(try container.decode(String.self, forKey: .value))
        case .int: self = .int(try container.decode(Int.self, forKey: .value))
        case .double: self = .double(try container.decode(Double.self, forKey: .value))
        case .bool: self = .bool(try container.decode(Bool.self, forKey: .value))
        case .date: self = .date(try container.decode(Date.self, forKey: .value))
        case .eventType: self = .eventType(try container.decode(Event.EventType.self, forKey: .value))
        case .eventLocation: self = .eventLocation(try container.decode(EventLocation.self, forKey: .value))
        case .stringArray: self = .stringArray(try container.decode([String].self, forKey: .value))
        case .null: self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let v):
            try container.encode(ValueType.string, forKey: .type)
            try container.encode(v, forKey: .value)
        case .int(let v):
            try container.encode(ValueType.int, forKey: .type)
            try container.encode(v, forKey: .value)
        case .double(let v):
            try container.encode(ValueType.double, forKey: .type)
            try container.encode(v, forKey: .value)
        case .bool(let v):
            try container.encode(ValueType.bool, forKey: .type)
            try container.encode(v, forKey: .value)
        case .date(let v):
            try container.encode(ValueType.date, forKey: .type)
            try container.encode(v, forKey: .value)
        case .eventType(let v):
            try container.encode(ValueType.eventType, forKey: .type)
            try container.encode(v, forKey: .value)
        case .eventLocation(let v):
            try container.encode(ValueType.eventLocation, forKey: .type)
            try container.encode(v, forKey: .value)
        case .stringArray(let v):
            try container.encode(ValueType.stringArray, forKey: .type)
            try container.encode(v, forKey: .value)
        case .null:
            try container.encode(ValueType.null, forKey: .type)
        }
    }
}
