//
//  EventImageCard.swift
//  Scoop
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

struct EventImageCard: View {

    let profileImages: [UIImage]
    let userImage: UIImage
    
    let targetTime: Date
        
    let openProfile: () -> ()
    
    var body: some View {
        VStack(spacing: 6) {
            CardImageScrollView(images: profileImages).onTapGesture {openProfile()}
            timerSection
        }
        .eventCardBackground()
    }
}

extension EventImageCard {
    
    private var timerSection: some View {
        HStack(spacing: 20) {
            photoOverlap
            clockView
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
    
    var photoOverlap: some View {
        ZStack(alignment: .topLeading) {
            SmallImage(image: userImage, size: 38, isCircle: true)
                .circleStroke(lineWidth: 1.5, color: .appCanvas)
            
            SmallImage(image: profileImages.first ?? UIImage(), size: 38, isCircle: true)
                .circleStroke(lineWidth: 1.5, color: .appCanvas)
                .offset(x: 16, y: 14)
        }
        .frame(width: 60, height: 56, alignment: .topLeading)
    }
}

//All Logic relating to the clock view
extension EventImageCard {
    
    private var clockView: some View {
        CountdownTimer(targetTime: targetTime) { timeRemaining in
            let days = timeRemaining.day ?? 0
            let hours = timeRemaining.hour ?? 0
            let minutes = timeRemaining.minute ?? 0
            let seconds = timeRemaining.second ?? 0
            
            HStack(alignment: .top) {
                timeSection(time: days, type: "DAYS")
                timeDivider
                timeSection(time: hours, type: "HRS")
                timeDivider
                timeSection(time: minutes, type: "MIN")
                timeDivider
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

    private var timeDivider: some View {
        Capsule()
            .fill(Color.fillGray)
            .frame(width: 0.85, height: 14)
            .offset(y: -4)
            .frame(maxWidth: .infinity)
    }
}
