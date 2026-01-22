//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI
import FirebaseFunctions


struct EventView: View {
        
    let vm: EventViewModel
    
    @State var showEventDetails: Bool = false
    @State var selection: String?
    @State var showProfile: Bool = false
    
    @State var selectedProfile: ProfileModel?
    
    
    
    var body: some View {
        ZStack {
            Color.background
            TabView(selection: $selection) {
                ForEach(vm.events) { profile in
                    EventSlot(vm: vm, selectedProfile: $selectedProfile, profileModel: profile)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea(edges: .all)
    }
}
