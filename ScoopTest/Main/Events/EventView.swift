//
//  EventView.swift
//  ScoopTest
//
//  Created by Art Ostin on 04/08/2025.
//

import SwiftUI
import Combine


struct EventView: View {
    
    @Environment(\.appDependencies) private var dep
    @State var events: [(event: Event, user: UserProfile)] = []
    
    
    
    
    var body: some View {
        
        VStack {
            TabView {
                ForEach(events, id: \.event.id) {event in
                    VStack(spacing: 36) {
                        
                        if let urlString = event.user.imagePathURL?[0], let url = URL(string: urlString) {
                            imageContainer(url: url, size: 140, shadow: 0)
                        }
                        
                        countdownTimer(meetUpTime: event.event.time)
                        
                        Text(getDate(date: event.event.time))
                            .font(.body(24, .bold))
                        
                    
                    }.tag(event.event.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .task {
                loadEvents()
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


struct countdownTimer: View {
    
    
    let meetUpTime: Date?
    var cancellables = Set<AnyCancellable>()
    
    var hourRemaining = ""
    var minuteRemaining = ""
    var secondRemaining = ""
    
    
    var body: some View {
        
        HStack(spacing: 32) {
            clockSection(time: hourRemaining, sign: "hr")
            clockSection(time: minuteRemaining, sign: "m")
            clockSection(time: secondRemaining, sign: "s")
        }
        .foregroundStyle(.white)
        .frame(width: 253, height: 52)
        .background(Color.accent)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 2)
        
        
    }
    func clockSection(time: String, sign: String) -> some View {
        HStack(spacing: 5) {
            Text(time)
                .font(.custom("SFCompactRounded-Semibold", size: 28))
            Text(sign)
                .font(.custom("SFCompactRounded-Regular", size: 14))
                .offset(y: 5)
        }
    }
    
    mutating func starTimer() {
        Timer
            .publish(every: 1.0, on: .main, in: .common).autoconnect()
            .sink {_ in updateTimeRemaining()}
            .store(in: &cancellables)
    }
    
    mutating func updateTimeRemaining() {
        guard let meetUpTime = meetUpTime else { return }
        
        let timeRemaining = Calendar.current.dateComponents([.hour, .minute, .second], from: Date(), to: meetUpTime)
        let hour = max(0, timeRemaining.hour ?? 0)
        let minute = max(0, timeRemaining.minute ?? 0)
        let second = max(0, timeRemaining.second ?? 0)
        hourRemaining = String(format: "%02d", hour)
        minuteRemaining = String(format: "%02d", minute)
        secondRemaining = String(format: "%02d", second)
    }
}
