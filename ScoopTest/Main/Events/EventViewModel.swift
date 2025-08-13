//
//  EventViewModel.swift
//  ScoopTest
//
//  Created by Art Ostin on 05/08/2025.
//

import Foundation
import SwiftUI



@Observable class EventViewModel {
    
    var dep: AppDependencies
    
    init(dependencies: AppDependencies) {
        self.dep = dependencies
    }
    var userEvents: [UserEvent] = []
    
    var hasEvents: Bool { !userEvents.isEmpty }
    var currentEvent: Event?
    var currentUser: UserProfile?
    
    func fetchUserEvents() async throws {
        Task { userEvents = try await dep.profileManager.getUpcomingAcceptedEvents() }
    }
    
    func saveUserImagesToCache() async throws {
        let ids = Set(userEvents.map(\.otherUserId))
        let profiles: [UserProfile] = try await withThrowingTaskGroup(of: UserProfile.self) { group in
            for id in ids {
                group.addTask { try await self.dep.profileManager.getProfile(userId: id) } }
            var results: [UserProfile] = []
            for try await p in group { results.append(p) }
            return results
        }
        _ = await self.dep.cacheManager.loadProfileImages(profiles)
        print("saved Images to Cache")
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
     */
    
    
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

 for event in events {
     guard !events.contains(where: { $0.id == event.id }), let profile = dependencies.eventManager.getEventMatch(event: event) else { return}
     let eventMatch: EventMatch = EventMatch(event: event, profile: profile)
     userEvents.append(eventMatch)
 }
 */


/*
 @MainActor
 func fetchUserEvents() async throws {
     print("function run")
     let events = try await dep.eventManager.getUpcomingAcceptedEvents()
     let matches: [EventMatch] = try await withThrowingTaskGroup(of: EventMatch.self) { group in
         for event in events {
             group.addTask {
                 let profile = try await self.dep.eventManager.getEventMatch(event: event)
                 return EventMatch(event: event, profile: profile)
             }
         }
         return try await group.reduce(into: []) { $0.append($1) }
     }
     userEvents = matches
 }
 */
