//
//  EventImageCard.swift
//  Scoop
//
//  Created by Art Ostin on 10/06/2026.
//

import SwiftUI

struct EventImageCard: View {

    //Injected
    let profileID: String
    let profileImages: [UIImage]
    let userImage: UIImage
    let targetTime: Date
    let openProfile: () -> ()

    //Local view state
    @State private var scrollProgress: Double = 0

    var body: some View {
        VStack(spacing: Spacing.xs) {
            CardImageCarousel(images: profileImages, scrollProgress: $scrollProgress)
                .onTapGesture {openProfile()}
                //The morph flies a copy of this image, so the real one hides while the copy is on screen.
                .profileMorphSource(id: profileID, radii: .init(uniform: CornerRadius.image))
            timerSection
        }
        .clipShape(.rect(cornerRadius: CornerRadius.image))
        .eventCardBackground()
    }
}

extension EventImageCard {
    
    private var timerSection: some View {
        HStack(spacing: Spacing.lg) {
            photoOverlap
            clockView
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
    }
    
    var photoOverlap: some View {
        ZStack(alignment: .topLeading) {
            SmallImage(image: userImage, size: 38, isCircle: true)
                .circleStroke(lineWidth: 1.5, color: .appCanvas)
            
            SmallImage(image: profileImages.first ?? UIImage(), size: 38, isCircle: true)
                .circleStroke(lineWidth: 1.5, color: .appCanvas)
                .offset(x: 18, y: 15)
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
