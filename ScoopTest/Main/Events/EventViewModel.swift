//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation


struct EventMatch: Identifiable {
    let event: Event
    let user: UserProfile

    var id: String { event.id }
}




@Observable class EventViewModel {
    
    var dependencies: AppDependencies
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    
    var events: [EventMatch] = []
    
    var hasEvents: Bool { !events.isEmpty }
    
    var currentEvent: Event?
    var currentUser: UserProfile?
    
    
    func loadEvents() async {
        Task {
            do {
                let userEvents = try await dependencies.eventManager.getUserEvents()
                let newEvents = try await withThrowingTaskGroup(of: EventMatch.self) { group -> [EventMatch] in
                    for event in userEvents {
                        guard !events.contains(where:{ $0.event.id == event.id}) else { continue }
                        
                        group.addTask {
                            let match = try await self.dependencies.eventManager.getEventMatch(event: event)
                            return EventMatch(event: event, user: match)
                        }
                    }
                    var collected: [EventMatch] = []
                    for try await result in group {
                        collected.append(result)
                    }
                    return collected
                }
                events.append(contentsOf: newEvents)
                if currentEvent == nil, let first = events.first {
                    currentEvent = first.event
                    currentUser  = first.user
                }
            } catch {
                print("Failed to load events: \(error)")
            }
        }
    }
    
    
    func formatDate(date: Date?) -> String {
        guard let date = date else { return "" }
        let day = date.formatted(.dateTime.month(.abbreviated).day(.defaultDigits))
        let time = date.formatted(
            .dateTime
                .weekday(.wide)
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits))
        
        return "\(day), \(time)"
    }
    
}
