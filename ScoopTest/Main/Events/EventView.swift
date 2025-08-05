//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventView: View {
    
    @Environment(\.appDependencies) private var dep
    @State var events: [(event: Event, user: UserProfile)] = []
    

    
    
    var body: some View {
        
        VStack {
            TabView {
                ForEach(events, id: \.event.id) {event in
                    VStack {
                        if let urlString = event.user.imagePathURL?.first,
                           let url = URL(string: urlString) {
                            imageContainer(url: url, size: 140, shadow: 0)
                        }
                        
                        if let date = event.event.time {
                            let datePart = date.formatted(.dateTime.day(.ordinal).month(.abbreviated))
                            let rest = date.formatted(
                                .dateTime
                                    .weekday(.wide)
                                    .hour(.twoDigits(amPM: .omitted))
                                    .minute(.twoDigits)
                            )
                            Text("\(datePart), \(rest)")
                                .font(.body(24, .bold))
                        }
 
                    }.tag(event.event.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .task {
                loadEvents()
            }
        }
    }
}

extension EventView {
    
    
    private func loadEvents() {
        Task {
            do {
                let userEvents = try await dep.eventManager.getUserEvents()
                for event in userEvents {
                    guard !events.contains(where: { $0.event.id == event.id }) else { continue }
                    let match = try await dep.eventManager.getEventMatch(event: event)
                    events.append((event: event, user: match))
                }
            } catch {
                print("Failed to load events: \(error)")
            }
        }
    }
}
