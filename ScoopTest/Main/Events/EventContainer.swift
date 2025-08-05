//
//  EventContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventContainer: View {
    
    @State var vm: EventViewModel
    
    
    init(dependencies: AppDependencies) {
        _vm = State(initialValue: EventViewModel(dependencies: dependencies))
    }
    
    
    var body: some View {
        
        ZStack {
            
            if vm.showEvent {
                EventView(vm: $vm)
            } else {
                EventPlaceholder(vm: $vm)
            }
        }
        .task {
            let events = (try? await vm.dependencies.eventManager.getCurrentEvents()) ?? []
            vm.showEvent = !events.isEmpty
        }
    }
}

#Preview {
    EventContainer(dependencies: AppDependencies())
}
