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
            if vm.hasEvents {
                EventView(dep: vm.dep, vm: vm)
            } else {
                EventPlaceholder()
            }
        }
        .task {
            try? await vm.fetchUserEvents()
            try? await vm.saveUserImagesToCache()
        }
    }
}

#Preview {
    EventContainer(dependencies: AppDependencies())
}
