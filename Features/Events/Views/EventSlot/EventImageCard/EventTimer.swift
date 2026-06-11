//
//  EventClock.swift
//  Scoop Test
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
            circlePhoto(image: userImage)        // back photo

            circlePhoto(image: profileImage)       // front photo, overlaps
                .offset(x: 16, y: 14)
        }
        .frame(width: 60, height: 56, alignment: .topLeading)
    }

    
    func circlePhoto(image: UIImage) -> some View {
        CirclePhoto(image: image, showShadow: false, height: 38)
            .stroke(100, lineWidth: 1.5, color: Color.appCanvas)
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
                .font(.custom("SFProRounded-Bold", size: 28))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(Color(red: 0.55, green: 0, blue: 0.25))
            
            Text(type)
                .foregroundStyle(Color(white: 0.8))
                .font(.custom("SFProRounded-Medium", size: 8))
        }
        .frame(width: 37, height: 21)
    }
    
    private var divider: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(white: 0.8))
            .frame(width: 1, height: 14.5)
            .offset(y: -4)
            .frame(maxWidth: .infinity)
    }
}

