//
//  FetchEvents.swift
//  ScoopTest
//
//  Created by Art Ostin on 11/08/2025.
//

import SwiftUI

struct FetchEvents: View {
    
    
    var events: [Event] = []
    
    var body: some View {
        
        VStack {
            ForEach(events) {event in
                HStack {
                    Text(event.recipientId ?? "")
                }
                
            }
        }
    }
    
    
}

#Preview {
    FetchEvents()
}
