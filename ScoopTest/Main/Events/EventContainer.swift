//
//  EventContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventContainer: View {
    
    @Environment(\.appDependencies) private var dep
        
    @State var showEvent: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if showEvent {
                EventView()
            } else {
                EventPlaceholder()
            }
        }
        .task {
            let events = try? await dep.eventManager.getCurrentEvents()
            
            if events != nil {
                showEvent = true
            } else {
                showEvent = false
            }
        }
    }
}

#Preview {
    EventContainer()
}
