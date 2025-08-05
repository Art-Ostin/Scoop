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
        
        if type == "grabFood" {
            return "meal With"
        } else if type == "grabADrink" {
            return "Drink With"
        } else if type == "houseParty" {
            return "House Party With"
        } else if type == "doubleDate" {
            return "Double Date with"
        } else if type == "samePlace" {
            return "Event with"
        } else if type == "writeAMessage" {
            return "Meeting"
        }
    }

    
    func typeImage (type: String) -> String {
        if type == "grabFood" {
            return "DancingCats"
        } else if type == "grabADrink" {
            return "CoolGuys"
        } else if type == "houseParty" {
            return "EventCups"
        } else if type == "doubleDate" {
            return "DancingCats"
        } else if type == "samePlace" {
            return "CoolGuys"
        } else if type == "writeAMessage" {
            return "CoolGuys"
        } else {
            return ""
        }
    }
    
    
    func typeDescription (type: String) -> String {
        if type == "grabFood" {
            return "Go to" + event.location?.name ?? "the place" + "for " + getTime(date: event.date) + "and meet" + user.name ?? "them" + "there. Can text 1 hour before."
        } else if type == "grabADrink" {
            return "Go to the bar for" + getTime(date: event.date) + "and meet there. Can text 1 hour before"
        } else if type == "houseParty" {
            return "EventCups"
        } else if type == "doubleDate" {
            return "Bring a friend and head to" + event.location?.name ?? "the place" + "for" +  getTime(date: event.date) + ". You can text 30 mins before."
        } else if type == "samePlace" {
            return "Head to" + event.location?.name ?? "the venue" + "with your mates & meet them & their friends there. Can text 1 hour before"
        } else if type == "writeAMessage" {
            return "Just Head to" + event.location?.name ?? "the venue" + "and meet" + user.name ?? "them" + "there for" + getTime(date: event.date)
        } else {
            return ""
        }
    }
    
    
    private func getTime(date: Date?) -> String {
        guard let date = date else {return ""}
        
        let format = date.formatted(.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        return format
    }
}

struct EventDetailsView: View {
    
    @State var vm: EventDetailsViewModel
    
    
    init(user: UserProfile, event: Event) {
        self._vm = EventDetailsViewModel(event: event , user: user)
    }
    
    var body: some View {
        
        VStack(spacing: 72) {
            
            VStack(alignment: .leading, spacing: 32) {
                Text((vm.event.type? ?? "") + " " + Event.sample.profile2.name)
                    .font(.body(24, .bold))
                
                EventDetailSummaryView(isSheetView: true)
                    .font(.body(18, .regular))
                    .lineSpacing(8)
            }
            
            Image(vm.typeImage(type: Event.sample.type))
                .resizable()
                .scaledToFit()
                .frame(height: 240)
            
            VStack (alignment: .leading, spacing: 24) {
                
                Text("What To Do")
                    .font(.body(20, .bold))
                
                VStack(alignment: .leading, spacing: 24) {
                    Text(vm.typeDescription(type: Event.sample.type))
                    
                    (
                        Text("You’ve both confirmed so don’t worry, they’ll be there! If you stand them up you’ll be blocked. ")
                        +
                        Text ("Can’t make it?")
                            .foregroundStyle(Color.accent)
                    )
                }
                .font(.body(16, .regular))
                .lineSpacing(4)
            }
            .padding(.horizontal, 16)
        }
        
    }
}

#Preview {
    EventDetailsView()
}


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
