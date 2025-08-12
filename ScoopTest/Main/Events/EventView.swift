//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.

import SwiftUI

struct EventView: View {
    
    @Binding var vm: EventViewModel
    
    @State var showEventDetails: Bool = false
    @State var selection: String?
    @State var showProfile: Bool = false
    
    var body: some View {
        
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
                    VStack(spacing: 36) {
                        Text(event.type ?? "No Type")
                        
                        if let time = event.time {
                            LargeClockView(targetTime: time) {}
                        }
                                                
                        Text(vm.formatDate(date: event.time))
                            .font(.body(24, .bold))
                    }
                    .tag(event.id)
                    .frame(maxHeight: .infinity)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onAppear { selection = vm.currentEvent?.id }
        }
        //            .onChange(of: selection) { _, newId in
        //                guard let id = newId, let pair = vm.userEvents.first(where: { $0.id == id }) else { return }
        //                vm.currentEvent = pair.
        //                vm.currentUser  = pair.profile
        //            }
        
        .fullScreenCover(isPresented: $showProfile, content: {
            if let newUser = vm.currentUser {
                ProfileView(profile: newUser, dep: vm.dep)
            }
        })
        .sheet(isPresented: $showEventDetails) {
            if let newEvent = vm.currentEvent, let newUser = vm.currentUser {
                EventDetailsView(event: newEvent, user: newUser)
            } else {
                Text("No event selected")
            }
        }
    }
}
