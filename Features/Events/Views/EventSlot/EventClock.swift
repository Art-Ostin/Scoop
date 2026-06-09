//
//  EventClock.swift
//  Scoop Test
//
//  Created by Art Ostin on 09/06/2026.
//


import SwiftUI

struct EventClock: View {
    
    let targetTime: Date
    
    var body: some View {
        
        CountdownTimer(targetTime: targetTime) { timeRemaining in
            let days = timeRemaining.day ?? 0
            let hours = timeRemaining.hour ?? 0
            let minutes = timeRemaining.minute ?? 0
            let seconds = timeRemaining.second ?? 0
            
            HStack(alignment: .top) {
                timeSection(time: days, type: "DAYS")
                divider
                timeSection(time: hours, type: "HRS")
                divider
                timeSection(time: minutes, type: "MIN")
                divider
                timeSection(time: seconds, type: "SEC")
            }
            .modifier(ClockBackground())
            .overlay(alignment: .topLeading) {startsInView}
        }
    }
}

extension EventClock {
    private func timeSection(time: Int, type: String) -> some View {
        VStack(spacing: 2) {
            Text("\(time)")
                .font(.custom("SFProRounded-Semibold", size: 30))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(Color(red: 0.55, green: 0, blue: 0.25))
            
            Text(type)
                .foregroundStyle(Color(white: 0.8))
                .font(.custom("SFProRounded-Medium", size: 12))
        }
        .frame(width: 40, height: 21)
    }
    
    private var divider: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(white: 0.8))
            .frame(width: 1, height: 14.5)
            .offset(y: -4)
            .frame(maxWidth: .infinity)
    }
    
    private var startsInView: some View {
        Text("Starts in")
            .eventTextOverlay()
    }
}

struct ClockBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 32)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
            .stroke(16, lineWidth: 1, color: .accent)
            .eventCardShadowBackground()
    }
}

