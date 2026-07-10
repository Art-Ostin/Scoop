//
//  EventClock.swift
//  Scoop
//
//  Created by Art Ostin on 09/06/2026.
//


import SwiftUI

struct EventTimer: View {
    
    let userImage: UIImage
    let profileImage: UIImage
    
    let targetTime: Date
    
    var body: some View {
        
        HStack(spacing: 20) {
            photoOverlap
            
            clockView
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}



extension EventTimer {    
    var photoOverlap: some View {
        ZStack(alignment: .topLeading) {
            SmallPhoto(image: userImage, size: 38)
                .circleStroke(lineWidth: 1.5, color: .appCanvas)

            SmallPhoto(image: profileImage, size: 38)
                .circleStroke(lineWidth: 1.5, color: .appCanvas)
                .offset(x: 16, y: 14)
        }
        .frame(width: 60, height: 56, alignment: .topLeading)
    }
}




//All Logic for the clock
extension EventTimer {
    
    private var clockView: some View {
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
        }
    }
    
    private func timeSection(time: Int, type: String) -> some View {
        VStack(spacing: 0) {
            Text("\(time)")
                .font(.title(28))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(Color.textAccent)
            
            Text(type)
                .foregroundStyle(Color.textPlaceholder)
                .font(.title(8, .medium))
        }
        .frame(width: 37, height: 21)
    }
    
    private var divider: some View {
        Capsule()
            .fill(Color.fillGray)
            .frame(width: 0.85, height: 14)
            .offset(y: -4)
            .frame(maxWidth: .infinity)
    }
}

