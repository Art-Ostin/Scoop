//
//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation


enum EventType: CaseIterable {
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


struct Event {
    
    var profile: UserProfile
    var profile2: UserProfile
    var type: EventType
    var time: Date
    var location: String
    var message: String?
}


extension Event {
    static func sample(dependencies: AppDependencies) -> Event {
        Event(
            profile: dependencies.userStore.user!,
            profile2: dependencies.userStore.user!,
            type:  .houseParty,
            time:   Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            location: "Legless Arms",
            message: nil
        )
    }
}
