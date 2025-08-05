//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation


@Observable class EventViewModel {
    
    var dependencies: AppDependencies

    var showEvent: Bool = false
    
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var events: [(event: Event, user: UserProfile)] = []
    
    var currentEvent: Event?
    var currentUser: UserProfile?
    
    
    func loadEvents() {
        Task {
            do {
                let userEvents = try await dependencies.eventManager.getUserEvents()
                for event in userEvents {
                    guard !events.contains(where: { $0.event.id == event.id }) else { continue }
                    let match = try await dependencies.eventManager.getEventMatch(event: event)
                    events.append((event: event, user: match))
                }
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
