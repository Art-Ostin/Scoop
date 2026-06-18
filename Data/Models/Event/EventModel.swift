//  EventModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 26/06/2025.
//
import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    
    enum EventStatus: String, Codable, Equatable {
        case pending, accepted, declined, pastAccepted, cancelled, neverShowed
    }
    
    enum EventScope: String, Codable {
        case upcomingInvited, upcomingAccepted, pastAccepted
    }
        
    enum EventType: String, CaseIterable, Codable, Hashable {
        case socialMeet, doubleDate, drink, custom
    }
        
    //1: Event Identifiers
    @DocumentID var _id: String?
    var id: String { _id! } //To just get a non optional ID
    var initiatorId: String
    var recipientId: String
    
    //2: Event Information
    var type: EventType
    var proposedTimes: ProposedTimes
    var acceptedTime: Date?
    var location: EventLocation
    var message: String?
    
    //3: Event updatable Information
    var status: EventStatus = .pending
    var canText: Bool = false
    var earlyTerminatorID: String?

    //4. Meta data
    var changeLog: [ChangeLogEntry] = []
    @ServerTimestamp var date_created: Date?
    
    init?(draft: EventFieldsDraft, initiatorId: String, recipientId: String) {
        guard let location = draft.place else {
            return nil
        }

        self.initiatorId = initiatorId
        self.recipientId = recipientId
        self.type = draft.type
        self.proposedTimes = draft.time
        self.location = location
        self.message = draft.message
    }
}

extension Event {
    //Firestore field names (used for update/query keys to avoid typos).
    enum Field: String {
        case initiatorId, recipientId, type, proposedTimes, acceptedTime, location, message, status, canText, earlyTerminatorID, changeLog, date_created
    }
}

extension Event.EventType {
    
    var title: String {
        switch self {
            case .drink:
                return "Drink"
            case .doubleDate:
                return  "Double Date"
            case .socialMeet:
                return "Social"
            case .custom:
                return "Custom Meet"
            }
    }
    
    var longTitle: String {
        switch self {
            case .drink:
                return "Grab a Drink"
            case .doubleDate:
                return  "Double Date"
            case .socialMeet:
                return "Social Meet"
            case .custom:
                return "Custom Meet"
            }
    }
    
    var emoji: String {
        switch self {
            case .drink:
                return "🍻"
            case .doubleDate:
                return  "🎑"
            case .socialMeet:
                return "🪩"
            case .custom:
                return "✒️"
            }
    }
    
    var textPlaceholder: String {
        switch self {
            case .drink:
                return "E.g. Lets get a drink"
            case .doubleDate:
                return  "E.g. My friends instagram is @, let do a double dateee if you're down!"
            case .socialMeet:
                return "E.g. Some mates and I are going to SAT to see Overmono. We should pre Together!"
            case .custom:
                return "E.g. Throwing a house party on Friday, you should come along with your friends"
            }
    }
    
    var howItWorks: String {
        switch self {
        case .drink:
            return "Meet up just the two of you and grab a drink together"
        case .doubleDate:
            return "Both bring a friend and meet for a double Date"
        case .socialMeet:
            return "Go with hour friends to the venue and meet them & their friends there"
        case .custom:
            return "For a custom meet, do whatever the other person has proposed in the invite."
        }
    }
    
    func howItWorksEvent(_ name: String) -> String { //Update later
        switch self {
        case .drink:
            return "Meet up just the two of you and grab a drink together"
        case .doubleDate:
            return "Both bring a friend and meet for a double Date"
        case .socialMeet:
            return "Go with hour friends to the venue and meet them & their friends there"
        case .custom:
            return "For a custom meet, do whatever the other person has proposed in the invite."
            
        }
    }
    
    
    
    
    func howItWorksWithEvent(_ event: UserEvent) -> String {
        switch self {
        case .drink:
            return "When its time head to \(event.location.name ?? "the bar") and grab a drink together!"
        case .doubleDate:
            return "Both bring a friend and meet at \(event.location.name ?? "the venue") for a double Date!"
        case .socialMeet:
            return "Go with your friends to \(event.location.name ?? "the venue") and meet \(event.otherUserName) and their friends there."
        case .custom:
            return "For a custom meet, do whatever the other person has proposed in the invite."
        }
    }
    
    var image: String {
        switch self {
        case .drink: return "EventCups"
        case .doubleDate: return "CoolGuys"
        case .socialMeet: return "CoolGuys"
        case .custom: return "CoolGuys"
        }
    }
    
    // Drinks / double dates need at least two proposed times so the other party
    // has something to choose from; custom and social meets accept a single slot.
    var minProposedTimes: Int {
        switch self {
        case .drink, .doubleDate: return 2
        case .custom, .socialMeet: return 1
        }
    }
}


/*
 
 var description: (emoji: String, label: String) {
     switch self {
     case .drink:
         return ("🍻", "Drink")
     case .doubleDate:
         return ("🎑", "Double Date")
     case .socialMeet:
         return ("🪩", "Social")
     case .custom:
         return ("✒️", "Custom Meet")
     }
 }
 
 var longTitle: String {
     switch self {
     case .drink: return "Grab A Drink"
     case .doubleDate: return "Double Date"
     case .socialMeet: return "Social Meet"
     case .custom: return "Custom Meet"
     }
 }
 var description: (emoji: String, label: String) {
     switch self {
     case .drink:
         return ("🍻", "Drink")
     case .doubleDate:
         return ("🎑", "Double Date")
     case .socialMeet:
         return ("🪩", "Social")
     case .custom:
         return ("✒️", "Custom Meet")
     }
 }
 
 var longTitle: String {
     switch self {
     case .drink: return "Grab A Drink"
     case .doubleDate: return "Double Date"
     case .socialMeet: return "Social Meet"
     case .custom: return "Custom Meet"
     }
 }
 
 var title: String {
     switch self {
     case . drink:
         return "Drink"
     case .doubleDate:
         return "Double Date"
     case .socialMeet:
         return "Social"
     case .custom:
         return "Custom Meet"
     }
 }
 
 var textPlaceholder: String {
     switch self {
     case . drink:
         return "E.g. Lets get a drink"
     case .doubleDate:
         return "E.g. My friends instagram is @, let do a double dateee if you're down!"
     case .socialMeet:
         return "E.g. Some mates and I are going to SAT to see Overmono. We should pre Together!"
     case .custom:
         return "E.g. Throwing a house party on Friday, you should come along with your friends"
     }
 }
 
 var typeExplanation: String {
     switch self {
     case . drink:
         return "Meet up"
     case .doubleDate:
         return "E.g. My friends instagram is @, let do a double dateee if you're down!"
     case .socialMeet:
         return "E.g. Some mates and I are going to SAT to see Overmono. We should pre Together!"
     case .custom:
         return "E.g. Throwing a house party on Friday, you should come along with your friends"
     }
 }
 
 func howItWorks(userEvent: UserEvent?) -> String {
     if let event = userEvent {
         switch self {
         case .drink:
             return "When its time head to \(event.location.name ?? "the bar") and grab a drink together!"
         case .doubleDate:
             return "Both bring a friend and meet at \(event.location.name ?? "the venue") for a double Date!"
         case .socialMeet:
             return "Go with your friends to \(event.location.name ?? "the venue") and meet \(event.otherUserName) and their friends there."
         case .custom:
             return "For a custom meet, do whatever the other person has proposed in the invite."
         }
     } else {
         switch self {
         case .drink:
             return "E.g. Lets get a drink"
         case .doubleDate:
             return "E.g. My friends instagram is @, let do a double dateee if you're down!"
         case .socialMeet:
             return "E.g. Some mates and I are going to SAT to see Overmono. We should pre Together!"
         case .custom:
             return "E.g. Throwing a house party on Friday, you should come along with your friends"
         }
     }
 }
 */
