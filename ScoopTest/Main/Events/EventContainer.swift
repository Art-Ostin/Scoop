//
//  EventContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventContainer: View {
    
    @State var vm = EventViewModel()
    
    var body: some View {
        
        ZStack {
            
            if vm.showEvent {
                
            } else {
                EventPlaceholder()
            }
        }
        
    }
}

#Preview {
    EventContainer()
}
