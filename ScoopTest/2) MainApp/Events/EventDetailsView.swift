//
//  EventDetailsView.swift
//  ScoopTest
//
//  Created by Art Ostin on 30/06/2025.
//

import SwiftUI


@Observable class EventDetailsViewModel {
    
    func getEventTime(event: Event) -> String {
        return (event.time.formatted(.dateTime.hour().minute()))
    }
    
    func typeTitle (type: EventType) -> String {
        switch type {
        case .grabFood:
            return "Meal with"
        case .grabADrink:
            return "Drink with"
        case .doubleDate:
            return "Double Date with"
        case .houseParty:
            return "House Party with"
        case .samePlace:
            return "Event with"
        case .writeAMessage:
            return "Meeting"
        }
    }
    
    // Change When Genevieve Gives the Images
    func typeImage (type: EventType) -> String {
        switch type {
        case .grabFood:
            return "CoolGuys"
        case .grabADrink:
            return "CoolGuys"
        case .doubleDate:
            return "CoolGuys"
        case .houseParty:
            return "CoolGuys"
        case .samePlace:
            return "CoolGuys"
        case .writeAMessage:
            return "CoolGuys"
        }
    }
    
    
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
}

struct EventDetailsView: View {
    
    @State var vm = EventDetailsViewModel ()
    
    var body: some View {
        
        VStack(spacing: 72) {
            
            VStack(alignment: .leading, spacing: 32) {
                Text(vm.typeTitle(type: Event.sample.type) + " " + Event.sample.profile2.name)
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
