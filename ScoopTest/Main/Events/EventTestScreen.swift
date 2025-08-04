//
//  EventTestScreen.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventTestScreen: View {
    
    @Environment(\.appDependencies) private var dependencies
    
    @State var events: [Event] = []
    
    @State var showInfo: Bool = false
    
    var body: some View {
        
        VStack {
            ForEach(events) { event in
                Text(event.type ?? "")
                
                if event.status == .pending {
                    Text("Pending")
                }
                
                Button("Show PopUp") {
                }
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
    
    private func getProfile(event: Event) async throws -> UserProfile {
        let userId = event.profile1_id
        return try await dependencies.profileManager.getProfile(userId: userId ?? "")
    }
}

#Preview {
    EventTestScreen()
}
