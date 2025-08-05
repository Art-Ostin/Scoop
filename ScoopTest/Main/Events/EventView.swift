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
    
    @State var 
    
    var body: some View {
        
        VStack {
            TabView {
                ForEach(events, id: \.event.id) {event in
                    VStack {
                        
                            if let url = getImage(event: event.event) {
                                imageContainer(url: url, size: 140, cornerRadius: 10)
                        }
                        Text(event.event.type ?? "")
                        Text(event.user.name ?? "")
                    }.tag(event.event.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .task {
                await loadEvents()
                
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
    
    private func getImage(event: Event) async -> URL? {
        do {
            let profile = try await dep.eventManager.getEventMatch(event: event)
            guard
                let urlString = profile.imagePathURL?.first,
                let url = URL(string: urlString)
            else {
                return nil
            }
            return url
        } catch {
            print("failed to get image:", error)
            return nil
        }
    }
}
