//
//  EventTestScreen.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventTestScreen: View {
    
    @Environment(\.appDependencies) private var dependencies
    
    var events: [Event] = []
    
    var body: some View {
        
        VStack {
            ForEach(events) { event in
                Text(event.type ?? "")
            }
        }
        .task {
            do {
                events = try await dependencies.eventManager.getUserEvents()
            } catch {
                print("Error getting events")
            }
        }
    }
}

#Preview {
    EventTestScreen()
}
