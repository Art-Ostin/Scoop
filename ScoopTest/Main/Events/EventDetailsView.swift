//
//  EventDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI


enum EventDisplay: String {
    
    case grabFood = "Grab Food"
    case grabDrink = "Grab a Drink"
    case houseParty = "House Party"
    case doubleDate = "Double Date"
    case samePlace = "Same Place"
    case writeMessage = "Write a Message"
    
    var title: String {
        switch self {
        case .grabFood: return "meal With"
        case .grabDrink: return "Drink With"
        case .houseParty: return "House Party With"
        case .doubleDate: return "Double Date with"
        case .samePlace: return "Event with"
        case .writeMessage: return "Meeting"
        }
    }
    
    var image: String {
        switch self {
        case .grabFood: return "DancingCats"
        case .grabDrink: return "CoolGuys"
        case .houseParty: return "EventCups"
        case .doubleDate: return "DancingCats"
        case .samePlace: return "CoolGuys"
        case .writeMessage: return "CoolGuys"
        }
    }
    
    func description(event: Event, user: UserProfile) -> String {
        switch self {
        case .grabFood:
            let location = event.location?.name ?? "the place"
            let name = user.name ?? "them"
            return "Go to \(location) for \(EventDetailsViewModel.formatTime(date: event.time)) and meet \(name) there. Can text 1 hour before."
            
        case .grabDrink:
            let name = user.name ?? "them"
            return "Go to the bar for \(EventDetailsViewModel.formatTime(date: event.time)) and meet \(name) there. Can text 1 hour before"
        case .houseParty:
            return "Head to the house party and meet there. You can text 1 hour before"
        case .doubleDate:
            let location = event.location?.name ?? "the place"
            return "Bring a friend and head to \(location) for \(EventDetailsViewModel.formatTime(date: event.time)). You can text 30 mins before."
        case .samePlace:
            let location = event.location?.name ?? "the venue"
            return "Head to \(location) with your mates & meet them & their friends there. Can text 1 hour before"
        case .writeMessage:
            let location = event.location?.name ?? "the venue"
            let name = user.name ?? "them"
            return "Just head to \(location) and meet \(name) there for \(EventDetailsViewModel.formatTime(date: event.time))"
        }
    }
}


@Observable class EventDetailsViewModel {
    
    let event: Event
    let user: UserProfile
    
    private var eventType: EventDisplay? {
        EventDisplay(rawValue: event.type ?? "")
    }
    
    init (event: Event, user: UserProfile) {
        self.event = event
        self.user = user
    }
    
    func typeTitle() -> String { eventType?.title ?? "" }
    
    func typeImage() -> String { eventType?.image ?? "" }
    
    func typeDescription() -> String {
        guard let eventType = eventType else { return "" }
        return eventType.description(event: event, user: user)
    }
    
    static func formatTime(date: Date?) -> String {
        guard let date = date else { return "" }
        return date.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
    }
        
        func eventTimeString(date: Date?) -> String {
            guard let date = date else { return "" }
            
            let dayTime = date.formatted(
                .dateTime
                    .weekday(.wide)
                    .hour(.twoDigits(amPM: .omitted))
                    .minute(.twoDigits)
            )
            let dayAndMonth = date.formatted(
                .dateTime
                    .day(.defaultDigits)
                    .month(.wide)
            )
            return "\(dayAndMonth), \(dayTime)"
        }
        
}

struct EventDetailsView: View {
    
    @State var vm: EventDetailsViewModel
    
    init(event: Event, user: UserProfile) {
        _vm = State(initialValue: (EventDetailsViewModel(event: event, user: user)))
    }
        
    var body: some View {
        
        VStack(spacing: 72) {
            
            let time = Text(vm.eventTimeString(date: vm.event.time))
            let location = Text(vm.event.location?.name ?? "").foregroundStyle(.accent).font(.body(20, .bold))
            
            
            VStack(alignment: .leading, spacing: 16) {
                Text((vm.typeTitle()) + " " + (vm.user.name ?? ""))
                    .font(.body(24, .bold))
                
                Text("\(time) at \(location)")
                    .font(.body(20, .regular))
                    .padding(.horizontal, 32)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }
            
            Image(vm.typeImage())
                .resizable()
                .scaledToFit()
                .frame(height: 240)
            
            VStack (alignment: .leading, spacing: 24) {
                
                Text("What To Do")
                    .font(.body(20, .bold))
                
                VStack(alignment: .leading, spacing: 24) {
                    Text(vm.typeDescription())
                    Text("You’ve both confirmed so don’t worry, they’ll be there! If you stand them up you’ll be blocked. ")
                    Text ("Can’t make it?")
                        .foregroundStyle(Color.accent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.body(16, .regular))
                .lineSpacing(4)
            }
            .padding(.horizontal, 16)
        }
        
    }
}

//#Preview {
//    EventDetailsView()
//}
