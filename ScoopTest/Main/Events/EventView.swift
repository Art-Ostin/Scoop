//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI
import Combine


struct EventView: View {
    
    @Environment(\.appDependencies) private var dep
    @State var events: [(event: Event, user: UserProfile)] = []
    
    
    
    
    var body: some View {
        
        VStack {
            
            HStack {
                TitleSection()
                    .padding(.top, 72)
                    .padding(.horizontal, 32)
                
                Image(systemName: "info.circle.fill")
                    .frame(width: 20, height: 20)
            }
            
            TabView {
                ForEach(events, id: \.event.id) {event in
                    VStack(spacing: 36) {
                        
                        Text(event.user.name ?? "")
                            .font(.title)
                            .frame(maxWidth: .infinity)
                        
                        if let urlString = event.user.imagePathURL?[0], let url = URL(string: urlString) {
                            imageContainer(url: url, size: 140, shadow: 0)
                        }

                        if let date = event.event.time {
                            CountdownTimer(meetUpTime: date)
                        }
                        Text(getDate(date: event.event.time))
                            .font(.body(24, .bold))
                    
                    }.tag(event.event.id)
                        .frame(maxHeight: .infinity)
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
    
    private func getDate(date: Date?) -> String {
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
