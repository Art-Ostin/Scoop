//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventView: View {
    
    @Environment(\.appDependencies) private var dependencies
    
    @State var events: [Event] = []

    @State var userProfiles: [UserProfile] = []
    
    var body: some View {
        
        VStack {
            
            //Paste the Event  with its details, with the corresponding Event Match Profile photo
            
        }
        .task {
            do {
                self.events = try await dependencies.eventManager.getUserEvents()
                
                
            } catch {
            }
            
            ForEach(events) { event in
                dependencies.eventManager.getEventMatch(event: event)
            }
        }
        
        
    }
}

#Preview {
    EventView()
}
