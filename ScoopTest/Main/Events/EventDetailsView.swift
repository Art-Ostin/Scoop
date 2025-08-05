//
//  EventDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI


@Observable class EventDetailsViewModel {
    
    let event: Event
    let user: UserProfile
    
    init (event: Event, user: UserProfile) {
        self.event = event
        self.user = user
    }
    
    func typeTitle(type: String) -> String {
        if type == "Grab Food" {
            return "meal With"
        } else if type == "Grab a Drink" {
            return "Drink With"
        } else if type == "House Party" {
            return "House Party With"
        } else if type == "Double Date" {
            return "Double Date with"
        } else if type == "Same Place" {
            return "Event with"
        } else if type == "Write a Message" {
            return "Meeting"
        } else {
            return ""
        }
    }
    
    func typeImage (type: String) -> String {
        if type == "Grab Food" {
            return "DancingCats"
        } else if type == "Grab a Drink" {
            return "CoolGuys"
        } else if type == "House Party" {
            return "EventCups"
        } else if type == "Double Date" {
            return "DancingCats"
        } else if type == "Same Place" {
            return "CoolGuys"
        } else if type == "Write a Message" {
            return "CoolGuys"
        } else {
            return ""
        }
    }
    
    func typeDescription (type: String) -> String {
        switch type {
        case "Grab Food":
            let location = event.location?.name ?? "the place"
            let name = user.name ?? "them"
            return "Go to \(location) for \(getTime(date: event.time)) and meet \(name) there. Can text 1 hour before."
        case "Grab a Drink":
            let name = user.name ?? "them"
            return "Go to the bar for \(getTime(date: event.time)) and meet \(name) there. Can text 1 hour before"
        case "House Party":
            return "Head to the house party and meet there. You can text 1 hour before"
        case "Double Date":
            let location = event.location?.name ?? "the place"
            return "Bring a friend and head to \(location) for \(getTime(date: event.time)). You can text 30 mins before."
        case "Same Place":
            let location = event.location?.name ?? "the venue"
            return "Head to \(location) with your mates & meet them & their friends there. Can text 1 hour before"
        case "Write a Message":
            let location = event.location?.name ?? "the venue"
            let name = user.name ?? "them"
            return "Just head to \(location) and meet \(name) there for \(getTime(date: event.time))"
        default:
            return ""
        }
    }
    
    private func getTime(date: Date?) -> String {
        guard let date = date else {return ""}
        
        return date.formatted(
          .dateTime
            .hour(.twoDigits(amPM: .omitted))
            .minute(.twoDigits)
        )
    }
    
    func getEvenTime(date: Date?) -> String {
        guard let date = date else {return ""}
        
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
            
            let time = Text(vm.getEvenTime(date: vm.event.time))
            let location = Text(vm.event.location?.name ?? "").foregroundStyle(.accent).font(.body(20, .bold))
            
            
            VStack(alignment: .leading, spacing: 16) {
                Text((vm.typeTitle(type: vm.event.type ?? "")) + " " + (vm.user.name ?? ""))
                    .font(.body(24, .bold))
                
                
                Text("\(time) at \(location)")
                    .font(.body(20, .regular))
                    .padding(.horizontal, 32)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                
            }
            
            Image(vm.typeImage(type: vm.event.type ?? "No Image"))
                .resizable()
                .scaledToFit()
                .frame(height: 240)
            
            
            VStack (alignment: .leading, spacing: 24) {
                
                Text("What To Do")
                    .font(.body(20, .bold))
                
                VStack(alignment: .leading, spacing: 24) {
                    Text(vm.typeDescription(type: vm.event.type ?? "No Description"))
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


/*
 func typeDescription (type: EventType) -> String {
     switch type {
         
     case .grabFood:
         return "Go to" + Event.sample.location + "for " + getEventTime(event: .sample) + "and meet" + Event.sample.profile2.name + "there. Can text 1 hour before."
     case .grabADrink:
         return "Go to the bar for" + getEventTime(event: .sample) + "and meet there. Can text 1 hour before"
     case .doubleDate:
         return "Bring a friend and head to" + Event.sample.location + "for" +  getEventTime(event: .sample) + ". You can text 30 mins before."
     case .houseParty:
         return "Head to the house party with your friends and meet there. You can text 1 hour before."
     case .samePlace:
         return "Head to the venue with your mates & meet them & their friends there. Can text 1 hour before"
     case .writeAMessage:
         return "Just Head to" + Event.sample.location + "and meet" + Event.sample.profile2.name + "there for" + getEventTime(event: .sample)
     }
 }
 */
