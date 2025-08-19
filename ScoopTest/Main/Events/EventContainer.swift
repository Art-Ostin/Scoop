//
//  EventContainer.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventContainer: View {
    
    @State var vm: EventViewModel
    
    init(vm: EventViewModel) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        ZStack {
            if vm.hasEvents {
                EventView(vm: vm)
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
