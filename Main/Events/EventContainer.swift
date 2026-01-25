//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI

struct EventContainer: View {
    
    @State var vm: EventViewModel
    @State var showFrozenInfo: Bool?  //Need it for frozen view
    let isFrozenEvent: Bool

    init(vm: EventViewModel, showFrozenInfo: Binding<Bool?> = nil, isFrozenEvent: Bool = false) {
        _vm = State(initialValue: vm)
        self.showFrozenInfo = showFrozenInfo
        self.isFrozenEvent = isFrozenEvent
    }
    
    var body: some View {
        if !vm.events.isEmpty {
            EventView(vm: vm, showFrozenInfo: $showFrozenInfo, isFrozenEvent: false)
        } else {
            EventPlaceholder(vm: vm)
        }
    }
}
