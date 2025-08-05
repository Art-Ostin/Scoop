//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI


struct EventView: View {
    
    @Binding var vm: EventViewModel
    
    @State var showEventDetails: Bool = false
    @State var selection: Int? = nil
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
                
                ForEach(vm.events.indices, id: \.self) {index in
                    let event = vm.events[index]
                    
                    VStack(spacing: 36) {
                        
                        Text(event.user.name ?? "")
                            .font(.title)
                            .frame(maxWidth: .infinity)
                        
                        if let urlString = event.user.imagePathURL?[0], let url = URL(string: urlString) {
                            imageContainer(url: url, size: 140, shadow: 0)
                                .onTapGesture {
                                    showProfile.toggle()
                                }
                        }
                        if let date = event.event.time {
                            CountdownTimer(meetUpTime: date)
                        }
                        Text(vm.formatDate(date: event.event.time))
                            .font(.body(24, .bold))
                    }.tag(index)
                    .frame(maxHeight: .infinity)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .task {
                vm.loadEvents()
            }
            .onChange(of: selection) { _ , newIndex in
                let pair = vm.events[newIndex ?? 0]
                vm.currentEvent = pair.event
                vm.currentUser  = pair.user
            }
            .fullScreenCover(isPresented: $showProfile, content: {
                if let newUser = vm.currentUser {
                    ProfileView(profile: newUser)
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
}

