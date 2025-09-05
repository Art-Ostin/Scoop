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
            if !vm.events.isEmpty {
                EventView(vm: vm)
            } else {
                EventPlaceholder()
            }
        }
    }
}
