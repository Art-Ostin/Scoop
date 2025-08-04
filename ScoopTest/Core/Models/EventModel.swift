//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import MapKit



struct Event: Identifiable, Codable {
    var id = UUID().uuidString
    var profile: UserProfile
    var profile2: UserProfile
    var type: EventType?
    var time: Date?
    var location: EventLocation?
    var message: String?
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case profile
        case profile2
        case type
        case time
        case location
        case message
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.profile = try container.decode(UserProfile.self, forKey: .profile)
        self.profile2 = try container.decode(UserProfile.self, forKey: .profile2)
        self.type = try container.decodeIfPresent(EventType.self, forKey: .type)
        self.time = try container.decodeIfPresent(Date.self, forKey: .time)
        self.location = try container.decodeIfPresent(EventLocation.self, forKey: .location)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.profile, forKey: .profile)
        try container.encode(self.profile2, forKey: .profile2)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.time, forKey: .time)
        try container.encodeIfPresent(self.location, forKey: .location)
        try container.encodeIfPresent(self.message, forKey: .message)
    }
}



















enum EventType: CaseIterable, Codable {
    case grabFood
    case grabADrink
    case houseParty
    case doubleDate
    case samePlace
    case writeAMessage
}


extension EventType {
    var description: (emoji: String?, label: String) {
        switch self {
        case .grabFood:
            return ("🍕", "Grab Food")
        case .grabADrink:
            return ("🍻", "Grab a Drink")
        case .houseParty:
            return ("🎉", "House Party")
        case .doubleDate:
            return ("🎑", "Double Date")
        case .samePlace:
            return ("🕺🏻", "Same Place")
        case .writeAMessage:
            return ("✒️", "Write a Message")
        }
    }
}

