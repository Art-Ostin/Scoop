//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventView: View {
    
    @Environment(\.appDependencies) private var dependencies
    
    @State var events: [(event: Event, user: UserProfile)] = []
    
    
    var body: some View {
        
        VStack {
            
            TabView {
                ForEach(Array(events.enumerated()), id: \.element.event.id) {idx, event in

                    VStack {
                        Text(event.event.type ?? "")


                    }.tag(idx)

                
                    
                }
            }
            
        }.task {
            await loadEvents()
        }
    }
    
    private func loadEvents() async {
        
        
    }
}

#Preview {
    EventView()
}
