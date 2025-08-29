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
            VStack {
                HStack {
                    TitleSection()
                        .padding(.top, 72)
                        .padding(.horizontal, 32)
                    
                    Image(systemName: "info.circle")
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            showEventDetails.toggle()
                        }
                }

                TabView(selection: $selection) {
                    ForEach(vm.userEvents) { event in
                        EventSlot(vm: vm, event: event, selectedProfile: $selectedProfile)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
            
            if let profile = selectedProfile {
                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture { }
                    ProfileView(vm: ProfileViewModel(profileModel: profile, cacheManager: vm.cacheManager)) {
                        selectedProfile = nil
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showEventDetails) {
            if let newEvent = vm.currentEvent, let newUser = vm.currentUser {
                EventDetailsView(event: newEvent, user: newUser)
            } else {
                Text("No event selected")
            }
        }
    }
}
