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
        userEvents = try await dep.eventManager.getUpcomingAcceptedEvents()
    }
    
    func saveUserImagesToCache() async throws {
        let ids = Set(userEvents.map(\.otherUserId))
        let profiles: [UserProfile] = try await withThrowingTaskGroup(of: UserProfile.self) { group in
            for id in ids {
                group.addTask { try await self.dep.userManager.fetchUser(userId: id) } }
            var results: [UserProfile] = []
            for try await p in group { results.append(p) }
            return results
        }
        _ = await self.dep.cacheManager.loadProfileImages(profiles)
        print("saved Images to Cache")
    }
    
    //Remove from this Manager not relevant
    func eventFormatter (event: UserEvent, isInvite: Bool = true, size: CGFloat = 22) -> some View {
        
        var isMessage: Bool { event.message?.isEmpty == false }
        let time = formatTime(date: event.time)
        let type = event.type ?? ""
        let place = event.place?.name  ?? ""
        let header =  Text("\(time), \(type), ") + Text(place).foregroundStyle(isInvite ? Color.appGreen : Color.accent).font(.body(size, .bold))
        
        return VStack(alignment: isMessage ? .leading: .center, spacing: isMessage ? 16 : 0) {
            
            header
                .font(.body(size))
                .multilineTextAlignment(isMessage ? .leading : .center)
                .lineSpacing(isMessage ? 4 : 12)
            
            
            if let message = event.message {
                Text (message)
                    .font(.body(.italic))
                    .foregroundStyle(Color.grayText)
            }
        }
    }
    
    func formatTime(date: Date?) -> String {
        guard let date = date else { return "" }
        let dayOfMonth = date.formatted(.dateTime.month(.abbreviated).day(.defaultDigits))
        let weekDay = date.formatted(.dateTime.weekday(.wide))
        let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
        
        return "\(weekDay) (\(dayOfMonth)) \(time)"
    }

}
