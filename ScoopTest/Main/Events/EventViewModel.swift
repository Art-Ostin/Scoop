//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation
import AsyncAlgorithms


struct EventMatch: Identifiable {
    let event: Event
    let profile: UserProfile
    var id: String { event.id ?? ""}
}

@Observable class EventViewModel {
    
    var dep: AppDependencies
    
    init(dependencies: AppDependencies) {
        self.dep = dependencies
        Task { try? await fetchUserEvents() }
    }
    var userEvents: [EventMatch] = []
    
    var hasEvents: Bool { !userEvents.isEmpty }
    var currentEvent: Event?
    var currentUser: UserProfile?
    
    
    func fetchUserEvents() async throws {
        
        print("fetched Events called")
        let events = try await dep.eventManager.getUpcomingAcceptedEvents()

        let matches: [EventMatch] = try await withThrowingTaskGroup(of: EventMatch.self) { group in
            for event in events {
                guard !userEvents.contains(where: { $0.id == event.id }) else {return []}
                group.addTask {
                    let profile = try await self.dep.eventManager.getEventMatch(event: event)
                    return EventMatch(event: event, profile: profile)
                }
            }
            var out: [EventMatch] = []
            for try await m in group { out.append(m)  }
            return out
        }
        userEvents = matches
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


/*
 
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
 
 for event in events {
     guard !events.contains(where: { $0.id == event.id }), let profile = dependencies.eventManager.getEventMatch(event: event) else { return}
     let eventMatch: EventMatch = EventMatch(event: event, profile: profile)
     userEvents.append(eventMatch)
 }

 
 */
