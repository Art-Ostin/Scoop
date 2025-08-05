//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI


struct EventView: View {
    
    
    @Binding var vm: EventViewModel
    
    
    
    
    @Environment(\.appDependencies) private var dep
    
    @State var events: [(event: Event, user: UserProfile)] = []
    
    @State var currentEvent: Event?
    @State var currentUser: UserProfile?
    
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
                
                ForEach(events.indices, id: \.self) {index in
                    let event = events[index]
                    
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
                        Text(getDate(date: event.event.time))
                            .font(.body(24, .bold))
                    }.tag(index)
                    .frame(maxHeight: .infinity)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .task {
                loadEvents()
            }
            .onChange(of: selection) { _ , newIndex in
                let pair = events[newIndex ?? 0]
                currentEvent = pair.event
                currentUser  = pair.user
            }
            .fullScreenCover(isPresented: $showProfile, content: {
                if let newUser = currentUser {
                    ProfileView(profile: newUser)
                }
            })
            .sheet(isPresented: $showEventDetails) {
                if let newEvent = currentEvent, let newUser = currentUser {
                    EventDetailsView(event: newEvent, user: newUser)
                } else {
                    Text("No event selected")
                }
            }
        }
    }
}

extension EventView {
    
    
    private func loadEvents() {
        Task {
            do {
                let userEvents = try await dep.eventManager.getUserEvents()
                for event in userEvents {
                    guard !events.contains(where: { $0.event.id == event.id }) else { continue }
                    let match = try await dep.eventManager.getEventMatch(event: event)
                    events.append((event: event, user: match))
                }
                if currentEvent == nil, let first = events.first {
                    currentEvent = first.event
                    currentUser  = first.user
                    selection = 0
                }
            } catch {
                print("Failed to load events: \(error)")
            }
        }
    }
    
    private func getDate(date: Date?) -> String {
        guard let date = date else { return "" }
        let day = date.formatted(.dateTime.month(.abbreviated).day(.defaultDigits))
        let time = date.formatted(
            .dateTime
                .weekday(.wide)
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits))
        
        return "\(day), \(time)"
    }
}
