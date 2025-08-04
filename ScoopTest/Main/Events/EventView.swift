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
                ForEach(Array(events.enumerated()), id: \.element.event.id) {idx, event in

                    
                    
                    
                    
                    VStack {
                        Text(event.event.type ?? "")
                        
                        Text(event.user.name ?? "")
                        
                        
                    }.tag(idx)

                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                
            }
            
        }.task {
            try? await loadEvents()
        }
    }
}

#Preview {
    EventView()
}


extension EventView {
    
    
    private func loadEvents() async throws {
        let userEvents = try await dep.eventManager.getUserEvents()
        for event in userEvents {
            let match = try await dep.eventManager.getEventMatch(event: event)
            events.append((event: event, user: match))
        }
    }
    
    
}
