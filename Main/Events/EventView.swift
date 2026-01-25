//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI
import FirebaseFunctions


struct EventView: View {
    
    @State var ui = EventUIState()
    
    let vm: EventViewModel
    
    @State var showEventDetails: Bool = false
    @State var selection: String?
    @State var dismissOffset: CGFloat? = nil
    @State var profileImages: [String : [UIImage]] = [ : ]
    
    @Binding var showFrozenInfo: Bool
    let isFrozenEvent: Bool
    
    var body: some View {
        ZStack {
            Color.background
            TabView(selection: $selection) {
                ForEach(vm.events) { profile in
                    EventSlot(vm: vm, ui: ui, profileModel: profile, dismissOffset: $dismissOffset, isFrozenEvent: isFrozenEvent, showfrozenInfo: $showFrozenInfo)
                        .task {
                            let loadedImages = await vm.loadImages(profileModel: profile)
                            await MainActor.run {
                                profileImages[profile.id] = loadedImages
                            }
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            .background(Color.background)
            
            if let profile = ui.selectedProfile {
                ProfileView(vm: ProfileViewModel(profileModel: profile, cacheManager: vm.cacheManager), profileImages: profileImages[profile.id] ?? [], selectedProfile: $ui.selectedProfile, dismissOffset: $dismissOffset)
                    .id(profile.id)
                    .zIndex(1)
                    .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fullScreenCover(item: $ui.showMessageScreen) {profileModel in
            Text(profileModel.id)
        }
        .sheet(item: $ui.showEventDetails) { event in
            NavigationStack {
                EventDetails(vm: vm, event: event)
            }
        }
        .fullScreenCover(item: $ui.showCantMakeIt) { event in
            //Print can't make it here
        }
    }
}
